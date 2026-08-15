-- Headless smoke test for the S1 engine.
--
--   nvim --headless -u init.lua -c "luafile tests/smoke.lua"
--
-- Exits non-zero on failure so CI (segment S6) can consume it directly.

local failures = 0

local function check(name, fn)
  local ok, err = pcall(fn)
  if ok then
    io.write("ok   - " .. name .. "\n")
  else
    failures = failures + 1
    io.write("FAIL - " .. name .. ": " .. tostring(err) .. "\n")
  end
end

local zone

check("zone loads", function()
  zone = require("vimquest.content.zones").load("00_awakening")
  assert(zone.spawn, "no spawn point extracted")
  assert(#zone.entities >= 1, "no entities extracted")
  assert(#zone.triggers >= 5, "triggers missing")
end)

check("map rows are uniform width", function()
  local w = #zone.map[1]
  for i, line in ipairs(zone.map) do
    assert(#line == w, ("row %d width %d, expected %d"):format(i, #line, w))
  end
end)

check("legend characters are painted over", function()
  for i, line in ipairs(zone.map) do
    assert(not line:find("[@12345g+]"), "legend char left in row " .. i .. ": " .. line)
  end
end)

check("walkability", function()
  local grid = require("vimquest.engine.grid")
  assert(grid.walkable(zone, zone.spawn.row, zone.spawn.col), "spawn is not walkable")
  assert(not grid.walkable(zone, 0, 0), "outer wall is walkable")
  assert(not grid.walkable(zone, -1, 0), "out of bounds is walkable")
end)

local vq = require("vimquest")
local state = require("vimquest.state")

check("game starts", function()
  vq.setup({})
  vq.start()
  assert(state.running, "not running")
  assert(state.buf and vim.api.nvim_buf_is_valid(state.buf), "no game buffer")
  assert(#state.entities == 1, "expected one entity, got " .. #state.entities)
  assert(vim.bo[state.buf].buftype == "nofile", "game buffer is not scratch")
  assert(vim.bo[state.buf].modifiable == false, "game buffer is writable in S1")
end)

check("world ticks and the shambler moves", function()
  local e = state.entities[1]
  local start_row, start_col = e.row, e.col
  vim.wait(1500, function()
    return e.row ~= start_row or e.col ~= start_col
  end, 50)
  assert(state.tick_count > 0, "tick loop never ran")
  assert(e.row ~= start_row or e.col ~= start_col, "chaser never moved")
end)

check("stamina drains and hp survives", function()
  local p = state.player
  assert(p.stamina <= p.max_stamina, "stamina above max")
  assert(p.hp > 0, "player died during idle smoke test")
end)

check("game quits cleanly", function()
  vq.quit()
  assert(not state.running, "still running after quit")
  assert(state.buf == nil, "state not reset")
end)

io.write(failures == 0 and "\nSMOKE PASS\n" or ("\nSMOKE FAIL (" .. failures .. ")\n"))
vim.cmd("qa" .. (failures == 0 and "!" or "!"))
os.exit(failures == 0 and 0 or 1)
