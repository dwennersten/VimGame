-- Entity spawning and per-tick behaviour.
--
-- Behaviours are looked up by name from M.behaviours, so content files stay
-- declarative: a zone says `behaviour = "chaser"` and never contains logic.

local state = require("vimquest.state")
local grid = require("vimquest.engine.grid")

local M = {}

local next_id = 0

---@param spec table entity spec from zone content
---@return table
function M.spawn(spec)
  next_id = next_id + 1
  local e = {
    id = next_id,
    kind = spec.kind or "mob",
    name = spec.name or spec.kind or "thing",
    glyph = spec.glyph or "g",
    hl = spec.hl,
    row = spec.row,
    col = spec.col,
    hp = spec.hp or 1,
    behaviour = spec.behaviour or "idle",
    speed = spec.speed or 6, -- moves once every `speed` ticks
    ticks = 0,
  }
  table.insert(state.entities, e)
  return e
end

function M.clear()
  state.entities = {}
end

M.behaviours = {}

function M.behaviours.idle() end

---Walks one cell toward the player, preferring the longer axis.
function M.behaviours.chaser(e, ctx)
  local dr = grid.sign(ctx.prow - e.row)
  local dc = grid.sign(ctx.pcol - e.col)
  local candidates
  if math.abs(ctx.prow - e.row) >= math.abs(ctx.pcol - e.col) then
    candidates = { { dr, 0 }, { 0, dc } }
  else
    candidates = { { 0, dc }, { dr, 0 } }
  end
  for _, d in ipairs(candidates) do
    local nr, nc = e.row + d[1], e.col + d[2]
    if (d[1] ~= 0 or d[2] ~= 0) and grid.walkable(ctx.zone, nr, nc) then
      e.row, e.col = nr, nc
      return
    end
  end
end

---Paces left and right until it hits something solid.
function M.behaviours.pacer(e, ctx)
  e.dir = e.dir or 1
  local nc = e.col + e.dir
  if grid.walkable(ctx.zone, e.row, nc) then
    e.col = nc
  else
    e.dir = -e.dir
  end
end

---Advance every living entity by one tick.
---@param ctx table { zone, prow, pcol }
function M.update(ctx)
  for _, e in ipairs(state.entities) do
    if e.hp > 0 then
      e.ticks = e.ticks + 1
      if e.ticks >= e.speed then
        e.ticks = 0
        local fn = M.behaviours[e.behaviour] or M.behaviours.idle
        fn(e, ctx)
      end
    end
  end
end

return M
