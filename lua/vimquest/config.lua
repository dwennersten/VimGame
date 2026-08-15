-- Configuration defaults for VimQuest.
-- Everything tunable lives here so gameplay can be balanced without touching engine code.

local M = {}

M.defaults = {
  -- Engine
  tick_ms = 100, -- world tick interval

  -- Content
  start_zone = "00_awakening",

  -- Player
  player = {
    max_hp = 10,
    max_stamina = 100,
    stamina_regen = 0.5, -- per tick
  },

  -- Costs charged per keypress, by key. Spamming hjkl is meant to hurt;
  -- efficient motions (w, }, 5j) are nearly free. This is the anti-habit system.
  stamina_cost = {
    default = 0.5,
    h = 2,
    j = 2,
    k = 2,
    l = 2,
  },

  damage = {
    contact = 1, -- hp lost when a hostile shares your cell
    cooldown_ms = 600, -- min gap between contact hits
    exhaustion = 1, -- hp lost per second while stamina is empty
  },

  ui = {
    winbar = true,
    bar_width = 10,
  },

  -- Debug
  log_keys = true, -- keystroke recorder (needed by scoring/adaptive systems later)
  max_keylog = 5000,
}

M.options = vim.deepcopy(M.defaults)

---@param opts table|nil
---@return table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

return M
