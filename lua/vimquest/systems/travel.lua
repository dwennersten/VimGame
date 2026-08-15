-- Fast travel, which is just vim marks.
--
-- Standing on a shrine, `ma` binds it to mark a; `'a` from anywhere returns to
-- it, across zones. The mechanic is literally the vim feature it teaches, which
-- is the whole design rule of this game: nothing is a metaphor for a keystroke,
-- it *is* the keystroke.
--
-- `m` and `'` are intercepted with buffer-local maps that read the following
-- character themselves. Away from a shrine they explain what a shrine is
-- instead of silently doing nothing.

local state = require("vimquest.state")
local grid = require("vimquest.engine.grid")

local M = {}

---The shrine the player is standing on, if any.
---@return table|nil
function M.shrine_here()
  if not state.running or not state.win then
    return nil
  end
  local row, col = grid.cursor(state.win)
  for _, s in ipairs(state.zone.shrines or {}) do
    if s.row == row and s.col == col then
      return s
    end
  end
  return nil
end

---@param ch string
---@return boolean
local function is_mark_letter(ch)
  return type(ch) == "string" and #ch == 1 and ch:match("%l") ~= nil
end

---Bind the shrine under the player to a mark.
---@param ch string
---@return boolean bound
function M.mark(ch)
  if not is_mark_letter(ch) then
    state.say("Marks are a to z. Try ma.")
    return false
  end
  local shrine = M.shrine_here()
  if not shrine then
    state.say("Nothing here holds a mark. Shrines ( ^ ) do - stand on one and press m" .. ch .. ".")
    return false
  end
  state.shrines[ch] = {
    zone = state.zone.id,
    row = shrine.row,
    col = shrine.col,
    name = shrine.name or "shrine",
    zone_name = state.zone.name,
  }
  state.say(("%s is bound to mark '%s. Return from anywhere with '%s."):format(shrine.name or "The shrine", ch, ch))
  return true
end

---Travel to a bound shrine.
---@param ch string
---@return boolean travelled
function M.jump(ch)
  local place = state.shrines[ch]
  if not place then
    state.say(("No shrine is bound to '%s. Stand on a shrine ( ^ ) and press m%s."):format(tostring(ch), tostring(ch)))
    return false
  end
  if place.zone == state.zone.id then
    grid.set_cursor(state.win, place.row, place.col)
    require("vimquest.engine.collision").set_anchor(place.row, place.col)
    state.say(("Returned to %s."):format(place.name))
    return true
  end
  require("vimquest").travel(place.zone, { row = place.row, col = place.col })
  return true
end

---Bound shrines, for the journal and the travel panel.
---@return string[]
function M.report()
  local out = {}
  local letters = {}
  for ch in pairs(state.shrines) do
    table.insert(letters, ch)
  end
  table.sort(letters)
  for _, ch in ipairs(letters) do
    local p = state.shrines[ch]
    table.insert(out, ("  '%s   %s   (%s)"):format(ch, p.name, p.zone_name or p.zone))
  end
  if #out == 0 then
    out = { "  (none bound - stand on a shrine ( ^ ) and press ma)" }
  end
  return out
end

---Install the m / ' / ` intercepts on the game buffer.
---@param buf integer
function M.attach(buf)
  local function reader(fn)
    return function()
      -- getcharstr blocks, which pauses the world for as long as the player
      -- takes to finish the command. That is the honest behaviour: they are
      -- mid-keystroke, not idle.
      local ok, ch = pcall(vim.fn.getcharstr)
      if ok and ch and ch ~= "" and ch ~= "\27" then
        fn(ch)
      end
    end
  end
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "m", reader(M.mark), vim.tbl_extend("force", opts, { desc = "VimQuest: bind a shrine" }))
  vim.keymap.set("n", "'", reader(M.jump), vim.tbl_extend("force", opts, { desc = "VimQuest: travel to a shrine" }))
  vim.keymap.set("n", "`", reader(M.jump), vim.tbl_extend("force", opts, { desc = "VimQuest: travel to a shrine" }))
end

---@return table
function M.serialise()
  return vim.deepcopy(state.shrines)
end

---@param data table|nil
function M.restore(data)
  state.shrines = {}
  for ch, p in pairs(data or {}) do
    if type(p) == "table" and type(p.zone) == "string" and tonumber(p.row) and tonumber(p.col) then
      state.shrines[ch] = {
        zone = p.zone,
        row = tonumber(p.row),
        col = tonumber(p.col),
        name = p.name or "shrine",
        zone_name = p.zone_name,
      }
    end
  end
end

return M
