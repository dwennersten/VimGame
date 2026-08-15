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

  -- Combat: operators are attacks. A wrong edit never corrupts the map, it just
  -- costs stamina, so experimenting is cheap and the map is always authoritative.
  combat = {
    miss_stamina = 8, -- stamina burned by an edit that hits terrain or the wrong mob
    flash_ms = 300, -- how long a kill highlight lingers
    combo_window_ms = 4000, -- a kill this soon after the last one extends the combo
    combo_bonus = 0.25, -- xp multiplier added per combo step
    max_combo_bonus = 2.0, -- cap on that multiplier
  },

  skills = {
    base_level_xp = 20, -- xp from level 1 to 2
    level_xp_step = 15, -- extra xp required per level after that
    hp_per_level = 1, -- max_hp granted per character level
  },

  save = {
    enabled = true,
    autosave = true, -- write on zone clear and on quit
    -- Where progress lives. nil means stdpath("data")/vimquest/, the only place
    -- VimQuest is ever allowed to write. Tests point this at a temp directory so
    -- a test run can never touch real progress.
    dir = nil,
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
