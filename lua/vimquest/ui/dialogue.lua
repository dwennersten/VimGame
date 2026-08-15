-- Modal dialogue.
--
-- Triggers used to flash a single statusline line that vanished while you were
-- still reading it. Now the world freezes, the text sits in a panel, and you
-- dismiss it when you are done. Everything shown here also lands in the journal.

local panel = require("vimquest.ui.panel")

local M = {}

M.current = nil

---@param lines string|string[]
---@param opts table|nil { title, footer }
function M.show(lines, opts)
  opts = opts or {}
  if M.current then
    M.current.close()
    M.current = nil
  end
  local body = type(lines) == "table" and vim.deepcopy(lines) or { lines }
  M.current = panel.open({
    lines = body,
    title = opts.title or "The Buffer speaks",
    footer = opts.footer or "<CR> or <Esc> to continue   -   <F1> journal",
    on_close = function()
      M.current = nil
    end,
  })
end

function M.close()
  if M.current then
    M.current.close()
    M.current = nil
  end
end

return M
