-- The journal: every message from this run, readable at your own pace.
--
-- Deliberately a normal scrollable buffer, so j/k/gg/G/<C-d> practice happens
-- even while reading. The world is frozen while it is open.

local state = require("vimquest.state")
local panel = require("vimquest.ui.panel")

local M = {}

M.current = nil

function M.close()
  if M.current then
    M.current.close()
    M.current = nil
  end
end

function M.toggle()
  if M.current then
    M.close()
    return
  end
  if not state.running then
    return
  end

  local lines = {}
  if #state.journal == 0 then
    lines = { "Nothing has happened yet." }
  else
    for i, entry in ipairs(state.journal) do
      table.insert(lines, string.format("%2d. %s", i, entry))
      table.insert(lines, "")
    end
  end

  M.current = panel.open({
    lines = lines,
    title = "Journal - " .. (state.zone and state.zone.name or ""),
    footer = "j/k gg/G to scroll   -   <Esc> or q to close",
    on_close = function()
      M.current = nil
    end,
  })
  -- Scroll to the newest entry.
  pcall(vim.api.nvim_win_set_cursor, M.current.win, { math.max(1, #lines - 1), 0 })
end

return M
