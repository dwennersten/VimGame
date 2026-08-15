-- Terrain collision.
--
-- The player IS the cursor, so "walls" are enforced by watching CursorMoved and
-- snapping back when a move lands on a solid cell. Motions that would blink you
-- into a wall (like $ against a rock face) simply fail, which is the intended
-- game rule rather than a bug.

local state = require("vimquest.state")
local grid = require("vimquest.engine.grid")

local M = {}

M.group = vim.api.nvim_create_augroup("VimQuestCollision", { clear = true })

local last_row, last_col = 0, 0

---@param row integer
---@param col integer
function M.set_anchor(row, col)
  last_row, last_col = row, col
end

function M.attach()
  local buf = state.buf
  if not buf then
    return
  end
  local spawn = state.zone.spawn or { row = 0, col = 0 }
  M.set_anchor(spawn.row, spawn.col)

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = M.group,
    buffer = buf,
    callback = function()
      if not state.running or not state.win then
        return
      end
      local row, col = grid.cursor(state.win)
      if grid.walkable(state.zone, row, col) then
        M.set_anchor(row, col)
      else
        grid.set_cursor(state.win, last_row, last_col)
      end
    end,
  })
end

function M.detach()
  pcall(vim.api.nvim_clear_autocmds, { group = M.group })
end

return M
