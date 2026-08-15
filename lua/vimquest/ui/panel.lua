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
---@field freeze boolean|nil freeze the world while open (default true)
---@field on_close fun()|nil

---@param opts VimQuestPanelOpts
---@return table panel { buf, win, close }
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

  local panel = { buf = buf, win = win }
  local closed = false

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
