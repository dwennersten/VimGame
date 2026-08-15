-- Combat: operators are attacks.
--
-- Text-mobs ARE buffer text. In a combat zone the map buffer is unlocked and
-- every change is watched with nvim_buf_attach. The engine never parses
-- keystrokes to decide *whether* something died - it looks at the buffer - so
-- any equivalent keystroke path counts, which is what real fluency looks like.
-- The keylog is consulted only to decide *which* command earned the credit.
--
-- The authored zone map is always the source of truth and the buffer is a view
-- of it. That single rule is what makes wrong edits safe: a strike that hits
-- terrain, or the wrong operator on the right mob, simply repaints. Nothing the
-- player types can corrupt the world, so experimenting is cheap.

local state = require("vimquest.state")
local config = require("vimquest.config")
local grid = require("vimquest.engine.grid")
local skills = require("vimquest.systems.skills")

local M = {}

M.ns = vim.api.nvim_create_namespace("vimquest_combat_fx")

M.attached = false

local detached = true -- tells the buf_attach callback to unhook itself
local suppress = false -- true while WE are writing to the buffer
local dirty = false
local key_mark = 0

-- The region the player's edit touched, in the coordinates the buffer had
-- *before* the edit. Column precision matters: deleting one grub shifts the
-- rest of its line left, and a mob that merely slid sideways was not attacked.
local change = nil ---@type table|nil {srow, scol, erow, ecol}

--------------------------------------------------------------------------- map

---The buffer as it should look right now: authored terrain with every living
---mob painted on top.
---@return string[]
function M.compose()
  local zone = state.zone
  local lines = vim.deepcopy(zone.map)
  for _, m in ipairs(state.mobs) do
    if m.alive then
      local line = lines[m.row + 1]
      if line and m.col + #m.text <= #line then
        lines[m.row + 1] = line:sub(1, m.col) .. m.text .. line:sub(m.col + #m.text + 1)
      end
    end
  end
  return lines
end

---A cell the player can legally occupy, closest to the one asked for.
---@param row integer
---@param col integer
---@return integer row, integer col
local function safe_cell(row, col)
  local zone = state.zone
  row = math.max(0, math.min(#zone.map - 1, row))
  col = math.max(0, math.min(#zone.map[row + 1] - 1, col))
  if grid.walkable(zone, row, col) then
    return row, col
  end
  for step = 1, #zone.map[row + 1] do
    for _, c in ipairs({ col - step, col + step }) do
      if grid.walkable(zone, row, c) then
        return row, c
      end
    end
  end
  local spawn = zone.spawn
  return spawn.row, spawn.col
end

---Repaint the buffer from the authored map. Authoritative: whatever the player
---did to the text, this puts the world back.
function M.paint()
  local buf, win = state.buf, state.win
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local row, col = 0, 0
  if win and vim.api.nvim_win_is_valid(win) then
    row, col = grid.cursor(win)
  end

  suppress = true
  local ok, err = pcall(vim.api.nvim_buf_set_lines, buf, 0, -1, false, M.compose())
  suppress = false
  if not ok then
    vim.notify("VimQuest repaint failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  if win and vim.api.nvim_win_is_valid(win) then
    row, col = safe_cell(row, col)
    grid.set_cursor(win, row, col)
    require("vimquest.engine.collision").set_anchor(row, col)
  end
end

------------------------------------------------------------------------ combat

---Keys pressed since the last time we resolved a change, joined into one string.
---@return string
local function consume_keys()
  local log = state.keylog
  if key_mark > #log then
    key_mark = 0
  end
  local parts = {}
  for i = key_mark + 1, #log do
    parts[#parts + 1] = log[i].key
  end
  key_mark = #log
  return table.concat(parts)
end

---Does this command satisfy one of the mob's weaknesses? Patterns are matched
---against the TAIL, so any approach motions in front of the strike are ignored.
---@param mob table
---@param cmd string
---@return boolean
function M.matches(mob, cmd)
  for _, pat in ipairs(mob.weakness or {}) do
    local ok, found = pcall(string.match, cmd, pat .. "$")
    if ok and found then
      return true
    end
  end
  return false
end

---Did the edit actually land on this mob's body?
---@param mob table
---@param c table {srow, scol, erow, ecol} in pre-edit coordinates
---@return boolean
local function struck(mob, c)
  if mob.row < c.srow or mob.row > c.erow then
    return false
  end
  local lo = mob.row == c.srow and c.scol or 0
  local hi = mob.row == c.erow and c.ecol or math.huge
  -- Half-open spans: [mob.col, mob.col + #text) against [lo, hi).
  return mob.col < hi and mob.col + #mob.text > lo
end

---Highlight a kill for a moment and float the xp gained.
---@param mob table
---@param xp integer
---@param combo integer
local function flash(mob, xp, combo)
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local label = ("  +%d xp"):format(xp)
  if combo > 1 then
    label = label .. ("  x%d combo"):format(combo)
  end
  pcall(vim.api.nvim_buf_set_extmark, buf, M.ns, mob.row, mob.col, {
    end_col = mob.col + #mob.text,
    hl_group = "VimQuestKill",
    virt_text = { { label, "VimQuestXp" } },
    priority = 300,
  })
  vim.defer_fn(function()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_clear_namespace, buf, M.ns, 0, -1)
    end
  end, config.options.combat.flash_ms)
end

---@param mob table
---@param cmd string
local function kill(mob, cmd)
  local now = vim.uv.now()
  local cfg = config.options.combat
  if now - state.last_kill_ms <= cfg.combo_window_ms then
    state.combo = state.combo + 1
  else
    state.combo = 1
  end
  state.last_kill_ms = now
  state.stats.best_combo = math.max(state.stats.best_combo, state.combo)
  state.stats.kills = state.stats.kills + 1

  local multiplier = 1 + math.min(cfg.max_combo_bonus, (state.combo - 1) * cfg.combo_bonus)
  local xp = skills.award(mob.teaches or { operator = 1 }, multiplier)

  mob.alive = false
  if cmd ~= "" then
    state.last_attack = cmd
  end
  flash(mob, xp, state.combo)
  state.say(("You strike down the %s.  +%d xp%s"):format(
    mob.name,
    xp,
    state.combo > 1 and ("   x%d combo"):format(state.combo) or ""
  ))
end

---@param reason string
local function miss(reason)
  state.combo = 0
  state.stats.misses = state.stats.misses + 1
  local p = state.player
  if p then
    p.stamina = math.max(0, p.stamina - config.options.combat.miss_stamina)
  end
  state.say(reason)
end

---Judge whatever the player just did to the buffer, then repaint.
function M.resolve()
  if not M.attached or not state.running or not dirty then
    return
  end
  dirty = false
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local c = change
  change = nil
  if not c then
    return
  end

  local cmd = consume_keys()
  -- '.' repeats the previous strike, so credit the command it stands for.
  if cmd:match("%.$") and state.last_attack then
    cmd = state.last_attack
  end

  local killed, shrugged = {}, {}
  for _, m in ipairs(state.mobs) do
    if m.alive and struck(m, c) then
      if M.matches(m, cmd) then
        table.insert(killed, m)
      else
        table.insert(shrugged, m)
      end
    end
  end

  for _, m in ipairs(killed) do
    kill(m, cmd)
  end

  if #killed == 0 then
    if #shrugged > 0 then
      local m = shrugged[1]
      miss(("The %s shrugs it off.   Try:  %s"):format(m.name, m.hint or "?"))
    else
      miss("Your strike gouges the floor. The Buffer knits itself shut.")
    end
  end

  M.paint()

  -- A change-operator (cw, ci") drops you into insert mode; the strike is over,
  -- so snap back to normal before stray typing becomes another miss.
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) == "i" or mode:sub(1, 1) == "R" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end
end

------------------------------------------------------------------ lifecycle

---@param zone table
function M.attach(zone)
  M.detach()
  state.mobs = {}
  if not zone.combat then
    return
  end

  for i, def in ipairs(zone.mobs or {}) do
    local m = vim.deepcopy(def)
    m.id = i
    m.alive = true
    m.hint = m.hint or "?"
    table.insert(state.mobs, m)
  end

  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.bo[buf].modifiable = true
  M.attached = true
  detached = false
  dirty = false
  key_mark = #state.keylog
  change = nil

  M.paint()

  vim.api.nvim_buf_attach(buf, false, {
    -- on_bytes, not on_lines: only byte offsets say *which columns* the player
    -- edited, and a mob is only attacked if the edit overlapped its body.
    on_bytes = function(_, _, _, srow, scol, _, old_end_row, old_end_col)
      if detached or not state.running then
        return true
      end
      if suppress then
        return
      end
      local erow = srow + old_end_row
      -- old_end_col is an offset from scol only while the change stays on one row.
      local ecol = old_end_row == 0 and (scol + old_end_col) or old_end_col
      if not change then
        change = { srow = srow, scol = scol, erow = erow, ecol = ecol }
      else
        -- One command can arrive as several edits; take the region enclosing them.
        if srow < change.srow or (srow == change.srow and scol < change.scol) then
          change.srow, change.scol = srow, scol
        end
        if erow > change.erow or (erow == change.erow and ecol > change.ecol) then
          change.erow, change.ecol = erow, ecol
        end
      end
      dirty = true
      vim.schedule(function()
        local ok, err = pcall(M.resolve)
        if not ok then
          vim.notify("VimQuest combat error: " .. tostring(err), vim.log.levels.ERROR)
        end
      end)
    end,
    on_detach = function()
      M.attached = false
    end,
  })
end

function M.detach()
  detached = true
  dirty = false
  local buf = state.buf
  if M.attached and buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_clear_namespace, buf, M.ns, 0, -1)
    pcall(function()
      vim.bo[buf].modifiable = false
    end)
  end
  M.attached = false
end

---@return integer alive, integer total
function M.census()
  local alive, total = 0, 0
  for _, m in ipairs(state.mobs) do
    total = total + 1
    if m.alive then
      alive = alive + 1
    end
  end
  return alive, total
end

return M
