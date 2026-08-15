-- Headless smoke test for the VimQuest engine.
--
--   nvim --headless -u init.lua -c "luafile tests/smoke.lua"
--
-- Exits non-zero on failure so CI (segment S6) can consume it directly.
-- Combat is driven with real keystrokes through nvim_feedkeys, because the
-- whole point of the game is that genuine vim commands do the work.
--
-- Saving is redirected to a temp directory: a test run must never be able to
-- touch a player's real progress.

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

local save_dir = vim.fs.joinpath(vim.fn.tempname(), "vimquest-test")

local vq = require("vimquest")
local state = require("vimquest.state")
local zones = require("vimquest.content.zones")
local grid = require("vimquest.engine.grid")
local combat = require("vimquest.engine.combat")
local skills = require("vimquest.systems.skills")
local save = require("vimquest.save")
local dialogue = require("vimquest.ui.dialogue")
local journal = require("vimquest.ui.journal")
local cheatsheet = require("vimquest.ui.cheatsheet")

vq.setup({ save = { dir = save_dir } })

--------------------------------------------------------------------- zone data

local zone

check("zone 0 loads", function()
  zone = zones.load("00_awakening")
  assert(zone.spawn, "no spawn point extracted")
  assert(#zone.entities >= 1, "no entities extracted")
  assert(#zone.triggers >= 5, "triggers missing")
  assert(#zone.exits >= 1, "zone has no exit - the player cannot finish it")
  assert(zone.brief and #zone.brief > 3, "zone has no opening briefing")
  assert(zone.exits[1].to == "01_rotwood", "zone 0 does not lead anywhere")
  assert(zone.combat == false, "zone 0 must stay a read-only zone")
end)

check("every zone has uniform row widths", function()
  for _, id in ipairs({ "00_awakening", "01_rotwood" }) do
    local z = zones.load(id)
    local w = #z.map[1]
    for i, line in ipairs(z.map) do
      assert(#line == w, ("%s row %d width %d, expected %d"):format(id, i, #line, w))
    end
  end
end)

check("legend characters are painted over", function()
  -- '>' is intentionally left in place: the exit portal must stay visible.
  for i, line in ipairs(zone.map) do
    assert(not line:find("[@12345g]"), "legend char left in row " .. i .. ": " .. line)
  end
  local portals = 0
  for _, line in ipairs(zone.map) do
    portals = portals + select(2, line:gsub(">", ""))
  end
  assert(portals == #zone.exits, "portal glyphs do not match exit count")
end)

check("walkability", function()
  assert(grid.walkable(zone, zone.spawn.row, zone.spawn.col), "spawn is not walkable")
  assert(not grid.walkable(zone, 0, 0), "outer wall is walkable")
  assert(not grid.walkable(zone, -1, 0), "out of bounds is walkable")
end)

local rotwood

check("zone 1 extracts its text-mobs", function()
  rotwood = zones.load("01_rotwood")
  assert(rotwood.combat, "the Rotwood is not marked as a combat zone")
  assert(#rotwood.mobs >= 12, "expected a full roster, got " .. #rotwood.mobs)

  local kinds = {}
  for _, m in ipairs(rotwood.mobs) do
    kinds[m.kind] = (kinds[m.kind] or 0) + 1
    assert(m.text and #m.text > 0, "mob without a body")
    assert(m.weakness and #m.weakness > 0, m.kind .. " has no weakness")
    assert(m.teaches and next(m.teaches), m.kind .. " teaches nothing")
    -- The mob must fit on its row, or the buffer view would not match the map.
    local line = rotwood.map[m.row + 1]
    assert(line and m.col + #m.text <= #line, m.kind .. " overhangs its row")
  end
  for _, kind in ipairs({ "grub", "word_mob", "quoted_imp", "bracket_troll", "line_wraith", "swarm" }) do
    assert(kinds[kind], "the Rotwood teaches nothing about " .. kind)
  end
end)

check("mob runs of the wrong length are rejected", function()
  local ok = pcall(function()
    -- A three-character body authored as a two-character run must not load.
    package.loaded["vimquest.content.zones.zz_broken"] = {
      id = "zz_broken",
      map = { "#####", "#.rr#", "#####" },
      legend = { ["r"] = { type = "mob", mob = "word_mob", text = "rot" } },
    }
    zones.load("zz_broken")
  end)
  package.loaded["vimquest.content.zones.zz_broken"] = nil
  assert(not ok, "a mistyped mob run loaded silently")
end)

------------------------------------------------------------------- zone 0 flow

check("game starts with a briefing that freezes the world", function()
  vq.start()
  assert(state.running, "not running")
  assert(dialogue.current, "no opening briefing panel")
  assert(state.dialog_open, "briefing did not freeze the world")
  assert(#state.journal > 0, "briefing was not written to the journal")
  assert(state.buf and vim.api.nvim_buf_is_valid(state.buf), "no game buffer")
  assert(#state.entities == 1, "expected one entity, got " .. #state.entities)
  assert(vim.bo[state.buf].buftype == "nofile", "game buffer is not scratch")
  assert(vim.bo[state.buf].modifiable == false, "a non-combat zone must stay locked")
end)

check("dismissing the briefing resumes the world", function()
  dialogue.close()
  assert(not state.dialog_open, "world still frozen after dismissing briefing")
  assert(vim.api.nvim_get_current_buf() == state.buf, "focus did not return to the map")
end)

check("journal opens, holds the briefing, and closes", function()
  journal.toggle()
  assert(journal.current, "journal did not open")
  assert(state.dialog_open, "journal did not freeze the world")
  local lines = vim.api.nvim_buf_get_lines(journal.current.buf, 0, -1, false)
  assert(#lines > 1, "journal is empty")
  journal.toggle()
  assert(not journal.current, "journal did not close")
  assert(not state.dialog_open, "world still frozen after closing journal")
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

check("stepping onto the portal completes the zone", function()
  local ex = zone.exits[1]
  grid.set_cursor(state.win, ex.row, ex.col)
  require("vimquest.engine.collision").set_anchor(ex.row, ex.col)
  vim.wait(2000, function()
    return state.dialog_open
  end, 50)
  assert(state.dialog_open, "no ZONE CLEARED panel after reaching the portal")
  assert(state.zones_cleared["00_awakening"], "clearing the zone was not recorded")
end)

check("game quits cleanly", function()
  vq.quit()
  assert(not state.running, "still running after quit")
  assert(state.buf == nil, "state not reset")
end)

------------------------------------------------------------------------ combat

---Find the first living mob of a kind.
---@param kind string
---@return table
local function find(kind)
  for _, m in ipairs(state.mobs) do
    if m.alive and m.kind == kind then
      return m
    end
  end
  error("no living " .. kind .. " in the zone")
end

---Press keys for real and wait for combat to settle.
---@param mob table|nil the mob expected to die, or nil to just wait
---@param keys string
local function strike(mob, keys)
  local before = state.stats.kills + state.stats.misses
  -- "t" marks these as typed, so the keylog sees them exactly as it would see a
  -- human pressing them. Without it they arrive as untyped input and the
  -- recorder correctly ignores them.
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
  vim.wait(1000, function()
    if mob then
      return not mob.alive
    end
    return state.stats.kills + state.stats.misses > before
  end, 20)
end

check("the Rotwood unlocks the buffer and paints its mobs", function()
  vq.start("01_rotwood")
  dialogue.close()
  assert(vim.bo[state.buf].modifiable, "a combat zone must unlock the buffer")
  assert(combat.attached, "combat watcher is not attached")
  assert(#state.mobs >= 12, "mobs were not spawned")

  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  local grub = find("grub")
  assert(lines[grub.row + 1]:sub(grub.col + 1, grub.col + #grub.text) == grub.text, "mob body is not in the buffer")
  -- The authored map underneath stays clean; the buffer is only a view of it.
  assert(state.zone.map[grub.row + 1]:sub(grub.col + 1, grub.col + 1) == ".", "the map was overwritten by a mob")
end)

check("x kills a grub and awards xp", function()
  local grub = find("grub")
  local before = skills.get("operator").xp
  grid.set_cursor(state.win, grub.row, grub.col)
  strike(grub, "x")
  assert(not grub.alive, "the grub survived x")
  assert(skills.get("operator").xp > before or skills.get("operator").level > 1, "no xp for the kill")
  assert(state.stats.kills == 1, "kill was not counted")
  local line = vim.api.nvim_buf_get_lines(state.buf, grub.row, grub.row + 1, false)[1]
  assert(#line == #state.zone.map[grub.row + 1], "the row was not repaired after the kill")
end)

check("dw kills a blight-word", function()
  local word = find("word_mob")
  grid.set_cursor(state.win, word.row, word.col)
  strike(word, "dw")
  assert(not word.alive, "the blight-word survived dw")
  assert(state.stats.kills == 2, "kill was not counted")
end)

check('di" kills a quoted imp', function()
  local imp = find("quoted_imp")
  local before = skills.get("textobject").xp + (skills.get("textobject").level - 1) * 1000
  grid.set_cursor(state.win, imp.row, imp.col + 1)
  strike(imp, 'di"')
  assert(not imp.alive, 'the imp survived di"')
  local after = skills.get("textobject").xp + (skills.get("textobject").level - 1) * 1000
  assert(after > before, "killing an imp taught no text-object skill")
end)

check("ca( kills a bracket troll and leaves normal mode", function()
  local troll = find("bracket_troll")
  grid.set_cursor(state.win, troll.row, troll.col + 2)
  strike(troll, "ca(")
  assert(not troll.alive, "the troll survived ca(")
  vim.wait(300, function()
    return vim.api.nvim_get_mode().mode:sub(1, 1) == "n"
  end, 20)
  assert(vim.api.nvim_get_mode().mode:sub(1, 1) == "n", "a change-operator left the player stuck in insert")
end)

check("dd kills a line-wraith and restores the row", function()
  local wraith = find("line_wraith")
  local row = wraith.row
  grid.set_cursor(state.win, row, wraith.col)
  strike(wraith, "dd")
  assert(not wraith.alive, "the wraith survived dd")
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  assert(#lines == #state.zone.map, "the deleted line was not restored")
  assert(lines[row + 1] == state.zone.map[row + 1], "the wraith's row did not repaint to the authored map")
end)

check("a single dw is not enough for a swarm", function()
  local swarm = find("swarm")
  local misses = state.stats.misses
  grid.set_cursor(state.win, swarm.row, swarm.col)
  strike(nil, "dw")
  assert(swarm.alive, "the swarm died to a single dw")
  assert(state.stats.misses > misses, "a wrong strike was not counted as a miss")
  local line = vim.api.nvim_buf_get_lines(state.buf, swarm.row, swarm.row + 1, false)[1]
  assert(line:sub(swarm.col + 1, swarm.col + #swarm.text) == swarm.text, "the swarm was not repainted intact")
end)

check("3dw kills the swarm", function()
  local swarm = find("swarm")
  grid.set_cursor(state.win, swarm.row, swarm.col)
  strike(swarm, "3dw")
  assert(not swarm.alive, "the swarm survived 3dw")
  assert(skills.get("count").xp > 0 or skills.get("count").level > 1, "counts did not level")
end)

check("editing terrain repaints instead of corrupting the map", function()
  local misses = state.stats.misses
  -- A wall, as far from any mob as the map allows.
  local row, col = 0, 5
  vim.api.nvim_win_set_cursor(state.win, { row + 1, col })
  strike(nil, "x")
  assert(state.stats.misses > misses, "gouging terrain was not a miss")
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  assert(lines[row + 1] == state.zone.map[row + 1], "terrain was not repaired")
  assert(state.combo == 0, "a miss did not break the combo")
end)

check("the cheatsheet reflects what has been learned", function()
  local lines = cheatsheet.lines()
  local text = table.concat(lines, "\n")
  assert(text:find("Text objects", 1, true), "text objects stayed locked after killing an imp")
  assert(text:find("Skills", 1, true), "the cheatsheet shows no skill report")
  cheatsheet.toggle()
  assert(cheatsheet.current and state.dialog_open, "the cheatsheet did not open and freeze the world")
  cheatsheet.toggle()
  assert(not cheatsheet.current and not state.dialog_open, "the cheatsheet did not close")
end)

----------------------------------------------------------------------- saving

local levels_before, xp_before

check("quitting writes a save", function()
  skills.ensure()
  levels_before = skills.get("operator").level
  xp_before = skills.get("operator").xp
  vq.quit()
  assert(save.exists(), "no save file at " .. save.path())
  local data = assert(save.read())
  assert(data.schema_version == save.SCHEMA_VERSION, "save is not stamped with the schema version")
  assert(data.skills.operator, "skills were not serialised")
end)

check("progress survives a relaunch", function()
  vq.start("01_rotwood")
  dialogue.close()
  assert(skills.get("operator").level == levels_before, "operator level was not restored")
  assert(skills.get("operator").xp == xp_before, "operator xp was not restored")
  assert(state.zones_cleared["00_awakening"], "cleared zones were not restored")
  assert(state.stats.kills > 0, "lifetime kills were not restored")
  -- Mobs are fresh again: progression persists, the world does not.
  assert(#state.mobs >= 12, "the zone did not repopulate")
  local alive = select(1, combat.census())
  assert(alive == #state.mobs, "a killed mob stayed dead across runs")
  vq.quit()
end)

check("an older save migrates forward", function()
  local legacy = {
    skills = { operator = { xp = 3, level = 4 } },
    zones_cleared = { ["00_awakening"] = true },
    stats = { kills = 99 },
  }
  vim.fn.mkdir(save.dir(), "p")
  vim.fn.writefile({ vim.json.encode(legacy) }, save.path())

  local data = assert(save.read())
  assert(data.schema_version == save.SCHEMA_VERSION, "migration did not stamp the new version")
  assert(data.skills.operator.level == 4, "migration lost skill levels")

  vq.start("01_rotwood")
  dialogue.close()
  assert(skills.get("operator").level == 4, "migrated levels did not reach the player")
  assert(state.stats.kills == 99, "migrated totals did not reach the player")
  assert(state.player.max_hp > require("vimquest.config").options.player.max_hp, "levels granted no health")
  vq.quit()
end)

check("reset erases progress", function()
  assert(save.exists(), "nothing to reset")
  vq.reset()
  assert(not save.exists(), "the save file survived a reset")
end)

check("nothing was written outside the test save directory", function()
  local real = vim.fs.joinpath(vim.fn.stdpath("data"), "vimquest", "save.json")
  assert(save.dir():find("vimquest%-test"), "the test was not redirected away from real progress")
  assert(vim.fn.isdirectory(save_dir) == 1 or not save.exists(), "test save directory missing")
  assert(real ~= save.path(), "the test wrote to the real save path")
end)

io.write(failures == 0 and "\nSMOKE PASS\n" or ("\nSMOKE FAIL (" .. failures .. ")\n"))
vim.cmd("qa!")
os.exit(failures == 0 and 0 or 1)
