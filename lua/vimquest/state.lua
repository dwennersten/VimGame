-- Runtime state singleton.
-- Nothing here is persisted directly; save/ (segment S2) will serialise a subset.

local M = {}

---@class VimQuestPlayer
---@field hp number
---@field max_hp number
---@field stamina number
---@field max_stamina number
---@field level number
---@field xp number

M.running = false
M.paused = false
M.buf = nil ---@type integer|nil
M.win = nil ---@type integer|nil
M.tab = nil ---@type integer|nil
M.zone = nil ---@type table|nil
M.entities = {} ---@type table[]
M.player = nil ---@type VimQuestPlayer|nil
M.keylog = {} ---@type table[]
M.last_hit_ms = 0
M.last_exhaust_ms = 0
M.messages = {} ---@type string[] last few lines, for the statusline
M.journal = {} ---@type string[] everything said this run, for the journal panel
M.dialog_open = false ---@type boolean world is frozen while a panel is up
M.tick_count = 0

---Fresh player from config.
---@param cfg table
---@return VimQuestPlayer
function M.new_player(cfg)
  return {
    hp = cfg.player.max_hp,
    max_hp = cfg.player.max_hp,
    stamina = cfg.player.max_stamina,
    max_stamina = cfg.player.max_stamina,
    level = 1,
    xp = 0,
  }
end

---Clear all volatile runtime state (called on quit).
function M.reset()
  M.running = false
  M.paused = false
  M.buf = nil
  M.win = nil
  M.tab = nil
  M.zone = nil
  M.entities = {}
  M.player = nil
  M.keylog = {}
  M.last_hit_ms = 0
  M.last_exhaust_ms = 0
  M.messages = {}
  M.journal = {}
  M.dialog_open = false
  M.tick_count = 0
end

---Record a message. The statusline keeps only the tail, but the journal keeps
---everything so nothing has to be read at speed.
---@param msg string|string[]
function M.say(msg)
  local lines = type(msg) == "table" and msg or { msg }
  for _, line in ipairs(lines) do
    if line ~= "" then
      table.insert(M.journal, line)
      table.insert(M.messages, line)
    end
  end
  while #M.messages > 3 do
    table.remove(M.messages, 1)
  end
end

return M
