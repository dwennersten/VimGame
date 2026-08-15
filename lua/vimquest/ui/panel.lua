-- Floating panel helper.
--
-- Every panel in the game (dialogue, journal, zone complete, later the skill
-- tree and cheat panel) is built from this. Panels freeze the world while open
-- via state.dialog_open, so reading is never punished by taking damage.

local state = require("vimquest.state")

local M = {}

---Word-wrap a line to a width.
---@param text string
---@param width integer
---@return string[]
function M.wrap(text, width)
  local out, line = {}, ""
  for word in text:gmatch("%S+") do
    if line == "" then
      line = word
    elseif #line + 1 + #word <= width then
      line = line .. " " .. word
    else
      table.insert(out, line)
      line = word
    end
  end
  if line ~= "" then
    table.insert(out, line)
  end
  if #out == 0 then
    out = { "" }
  end
  return out
end

---@param lines string[]
---@param width integer
---@return string[]
function M.wrap_all(lines, width)
  local out = {}
  for _, l in ipairs(lines) do
    if l == "" then
      table.insert(out, "")
    else
      vim.list_extend(out, M.wrap(l, width))
    end
  end
  return out
end

---@class VimQuestPanelOpts
---@field lines string[]
---@field title string|nil
---@field footer string|nil
---@field width integer|nil
---@field max_height integer|nil
---@field close_keys string[]|nil
---@field keys table<string, fun(panel: table)>|nil extra keymaps, e.g. choice selection
---@field freeze boolean|nil freeze the world while open (default true)
---@field on_close fun()|nil

---@param opts VimQuestPanelOpts
---@return table panel { buf, win, close, render, set_footer }
function M.open(opts)
  local width = opts.width or math.min(72, math.max(40, vim.o.columns - 12))
  local body = M.wrap_all(opts.lines, width - 4)
  local max_height = opts.max_height or math.max(6, vim.o.lines - 10)
  local height = math.min(#body, max_height)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, body)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "vimquestpanel"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 2),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = opts.title and (" " .. opts.title .. " ") or nil,
    title_pos = opts.title and "center" or nil,
    footer = opts.footer and (" " .. opts.footer .. " ") or nil,
    footer_pos = opts.footer and "center" or nil,
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false
  vim.wo[win].winhighlight = "Normal:VimQuestPanel,FloatBorder:VimQuestPanelBorder,FloatTitle:VimQuestHudGood"

  local freeze = opts.freeze ~= false
  if freeze then
    state.dialog_open = true
  end

  local panel = { buf = buf, win = win, width = width }
  local closed = false

  ---Replace the panel's contents and resize it to fit. Conversations redraw
  ---themselves this way as the player walks a dialogue tree.
  ---@param new_lines string[]
  function panel.render(new_lines)
    if closed or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local wrapped = M.wrap_all(new_lines, width - 4)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, wrapped)
    vim.bo[buf].modifiable = false
    if vim.api.nvim_win_is_valid(win) then
      -- Start from the live config so the title and border survive the resize.
      local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
      if ok then
        cfg.height = math.min(#wrapped, max_height)
        cfg.row = math.max(0, math.floor((vim.o.lines - cfg.height) / 2) - 2)
        cfg.col = math.max(0, math.floor((vim.o.columns - width) / 2))
        pcall(vim.api.nvim_win_set_config, win, cfg)
      end
    end
  end

  ---@param text string|nil
  function panel.set_footer(text)
    if closed or not vim.api.nvim_win_is_valid(win) then
      return
    end
    local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
    if not ok then
      return
    end
    cfg.footer = text and (" " .. text .. " ") or nil
    cfg.footer_pos = text and "center" or nil
    pcall(vim.api.nvim_win_set_config, win, cfg)
  end

  function panel.close()
    if closed then
      return
    end
    closed = true
    if freeze then
      state.dialog_open = false
    end
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
    -- Hand focus back to the world.
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      pcall(vim.api.nvim_set_current_win, state.win)
    end
    if opts.on_close then
      opts.on_close()
    end
  end

  for _, key in ipairs(opts.close_keys or { "<CR>", "<Esc>", "q", "<Space>" }) do
    vim.keymap.set("n", key, panel.close, { buffer = buf, nowait = true, silent = true })
  end
  -- Extra keys come after the close keys, so a panel that wants <CR> for
  -- something else (a conversation choosing a reply) can claim it.
  for key, fn in pairs(opts.keys or {}) do
    vim.keymap.set("n", key, function()
      fn(panel)
    end, { buffer = buf, nowait = true, silent = true })
  end

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      if freeze then
        state.dialog_open = false
      end
      closed = true
    end,
  })

  return panel
end

return M
