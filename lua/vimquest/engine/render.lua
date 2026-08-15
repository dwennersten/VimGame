-- Window / buffer lifecycle and drawing.
--
-- The map is real buffer text (so later segments can let operators literally
-- edit the world). Entities are drawn as overlay extmarks on top of that text,
-- which keeps the underlying map intact.

local state = require("vimquest.state")

local M = {}

M.ns = vim.api.nvim_create_namespace("vimquest_render")

local HL = {
  VimQuestWall = { fg = "#5b5768", bold = true },
  VimQuestFloor = { fg = "#2f2b38" },
  VimQuestSign = { fg = "#c8b48a" },
  VimQuestMob = { fg = "#e05252", bold = true },
  VimQuestHudGood = { fg = "#8fbf6f", bold = true },
  VimQuestHudWarn = { fg = "#d9a441", bold = true },
  VimQuestHudBad = { fg = "#e05252", bold = true },
  VimQuestHudDim = { fg = "#6c6880" },
  VimQuestHudText = { fg = "#cfc9dd" },
  VimQuestPanel = { fg = "#e0dcec", bg = "#1a1826" },
  VimQuestPanelBorder = { fg = "#7d6bb0", bg = "#1a1826" },
  VimQuestExit = { fg = "#6fd3bf", bold = true },
  -- Text-mobs: each kind reads differently at a glance, so you can pick the
  -- right command before you are standing on top of it.
  VimQuestMobGrub = { fg = "#c9d05b", bold = true },
  VimQuestMobWord = { fg = "#e07f3f", bold = true },
  VimQuestMobImp = { fg = "#c07fe0", bold = true },
  VimQuestMobTroll = { fg = "#e0c04a", bold = true },
  VimQuestMobWraith = { fg = "#8f8fe0", bold = true },
  VimQuestKill = { fg = "#ffffff", bg = "#7a2b2b", bold = true },
  VimQuestXp = { fg = "#8fbf6f", bold = true },
  VimQuestLocked = { fg = "#5b5768" },
}

function M.setup_highlights()
  for name, opts in pairs(HL) do
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end
end

---Open a dedicated tabpage for the game and paint the zone.
---@param zone table
function M.open(zone)
  M.setup_highlights()

  vim.cmd("tabnew")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].undolevels = -1
  vim.bo[buf].filetype = "vimquest"
  vim.api.nvim_buf_set_name(buf, "vimquest://" .. zone.id)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, zone.map)
  -- Locked in S1: stray keys cannot corrupt the map. Combat in S2 unlocks it.
  vim.bo[buf].modifiable = false

  local wo = vim.wo[win]
  wo.number = false
  wo.relativenumber = false
  wo.cursorline = true
  wo.cursorcolumn = false
  wo.wrap = false
  wo.list = false
  wo.spell = false
  wo.signcolumn = "no"
  wo.foldenable = false
  wo.scrolloff = 0
  wo.sidescrolloff = 0

  vim.api.nvim_buf_call(buf, function()
    vim.cmd([[syntax clear]])
    vim.cmd([[syntax match VimQuestWall /#/]])
    vim.cmd([[syntax match VimQuestFloor /\./]])
    vim.cmd([[syntax match VimQuestSign /[A-Za-z0-9!?'",:;()-]/]])
    vim.cmd([[syntax match VimQuestExit /[<>]/]])
  end)

  state.buf = buf
  state.win = win
  state.tab = vim.api.nvim_get_current_tabpage()
  state.zone = zone

  local spawn = zone.spawn or { row = 0, col = 0 }
  require("vimquest.engine.grid").set_cursor(win, spawn.row, spawn.col)
end

---Redraw entity overlays. Cheap enough to run every tick.
function M.draw()
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)

  local line_count = vim.api.nvim_buf_line_count(buf)

  -- Text-mobs are real buffer text, so they are coloured in place rather than
  -- overlaid. Dead ones simply stop being drawn - the map has already reclaimed
  -- their cells.
  for _, m in ipairs(state.mobs) do
    if m.alive and m.row >= 0 and m.row < line_count then
      pcall(vim.api.nvim_buf_set_extmark, buf, M.ns, m.row, m.col, {
        end_col = m.col + #m.text,
        hl_group = m.hl or "VimQuestMobWord",
        priority = 150,
      })
    end
  end

  for _, e in ipairs(state.entities) do
    if e.hp > 0 and e.row >= 0 and e.row < line_count then
      pcall(vim.api.nvim_buf_set_extmark, buf, M.ns, e.row, e.col, {
        virt_text = { { e.glyph, e.hl or "VimQuestMob" } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
        priority = 200,
      })
    end
  end
end

---Tear down the game tabpage.
function M.close()
  local tab = state.tab
  local buf = state.buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_clear_namespace, buf, M.ns, 0, -1)
  end
  if tab and vim.api.nvim_tabpage_is_valid(tab) then
    -- Closing the tabpage wipes the scratch buffer (bufhidden=wipe).
    if #vim.api.nvim_list_tabpages() > 1 then
      pcall(vim.api.nvim_set_current_tabpage, tab)
      pcall(vim.cmd, "tabclose")
    elseif buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

return M
