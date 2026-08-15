-- Grid helpers shared by collision, movement and rendering.
--
-- Coordinate convention used everywhere in the engine:
--   row: 0-indexed line number   (nvim_buf_* API convention)
--   col: 0-indexed byte column   (nvim_buf_* API convention)
-- Cursor APIs are 1-indexed for rows, so convert at the boundary only.
--
-- Maps are ASCII on purpose: byte columns and screen cells stay in sync,
-- which keeps collision and extmark overlays exact.

local M = {}

---Character at a grid position, or nil if out of bounds.
---@param zone table
---@param row integer 0-indexed
---@param col integer 0-indexed
---@return string|nil
function M.char_at(zone, row, col)
  local line = zone.map[row + 1]
  if not line then
    return nil
  end
  if col < 0 or col >= #line then
    return nil
  end
  return line:sub(col + 1, col + 1)
end

---Can an actor stand on this cell?
---@param zone table
---@param row integer
---@param col integer
---@return boolean
function M.walkable(zone, row, col)
  local ch = M.char_at(zone, row, col)
  if not ch then
    return false
  end
  return not zone.solid:find(ch, 1, true)
end

---Sign of a number: -1, 0 or 1.
---@param n number
---@return integer
function M.sign(n)
  if n > 0 then
    return 1
  elseif n < 0 then
    return -1
  end
  return 0
end

---Player position in grid coordinates.
---@param win integer
---@return integer row, integer col
function M.cursor(win)
  local pos = vim.api.nvim_win_get_cursor(win)
  return pos[1] - 1, pos[2]
end

---Move the cursor to a grid position.
---@param win integer
---@param row integer
---@param col integer
function M.set_cursor(win, row, col)
  pcall(vim.api.nvim_win_set_cursor, win, { row + 1, col })
end

return M
