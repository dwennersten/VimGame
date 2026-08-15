-- Quests and their objectives.
--
-- A quest is data: content/quests.lua for the hand-written ones, and
-- systems/bounties.lua generates radiant ones at runtime with the same shape.
-- Nothing here knows about any particular quest, and nothing in the engine
-- knows about quests at all - it just reports events.
--
-- Objective kinds, all declarative:
--   { kind = "kill",       mob = "<roster key>", count = n }
--   { kind = "kill_with",  mob = "<roster key>", command = "ca(", count = n }
--   { kind = "clear_zone", zone = "<zone id>" }
--   { kind = "reach",      zone = "<zone id>" }
--
-- Add a kind by adding a case to `advance` and a line to `describe`. Anything
-- more than that means the objective wants to be a new field instead.

local state = require("vimquest.state")

local M = {}

M.OFFERED = "offered"
M.ACTIVE = "active"
M.TURNED_IN = "turned_in"

---Every quest the player knows about, static or radiant.
---@param id string
---@return table|nil
function M.definition(id)
  local record = state.quests[id]
  if record and record.def then
    return record.def
  end
  return require("vimquest.content.quests")[id]
end

---@param id string
---@return table record created if missing
local function record(id)
  local r = state.quests[id]
  if not r then
    r = { status = M.OFFERED, progress = {} }
    state.quests[id] = r
  end
  return r
end

---@param id string
---@return string one of OFFERED / ACTIVE / TURNED_IN, or "unknown"
function M.status(id)
  local r = state.quests[id]
  return r and r.status or "unknown"
end

---Take on a quest. `def` is only needed for radiant quests, which have no
---entry in content/quests.lua and so must carry their definition with them.
---@param id string
---@param def table|nil
function M.accept(id, def)
  local r = record(id)
  if r.status == M.ACTIVE or r.status == M.TURNED_IN then
    return
  end
  r.status = M.ACTIVE
  r.progress = {}
  if def then
    r.def = def
  end
  local d = M.definition(id)
  state.say(("Quest accepted: %s"):format(d and d.name or id))
end

---@param id string
---@return boolean
function M.is_complete(id)
  local def = M.definition(id)
  local r = state.quests[id]
  if not def or not r or r.status ~= M.ACTIVE then
    return false
  end
  for i, obj in ipairs(def.objectives or {}) do
    if (r.progress[i] or 0) < (obj.count or 1) then
      return false
    end
  end
  return true
end

---@param obj table
---@param done integer
---@return string
function M.describe(obj, done)
  local target = obj.count or 1
  local text = obj.text
  if not text then
    if obj.kind == "kill" or obj.kind == "kill_with" then
      text = ("slay %d %s%s"):format(target, obj.mob, obj.command and (" with " .. obj.command) or "")
    elseif obj.kind == "clear_zone" then
      text = "clear " .. tostring(obj.zone)
    elseif obj.kind == "reach" then
      text = "travel to " .. tostring(obj.zone)
    else
      text = obj.kind or "?"
    end
  end
  if target > 1 then
    return ("[%d/%d] %s"):format(math.min(done, target), target, text)
  end
  return ("[%s] %s"):format(done >= target and "x" or " ", text)
end

---Credit one step of an objective and announce a quest that just finished.
---@param id string
---@param index integer
---@param amount integer
local function credit(id, index, amount)
  local r = state.quests[id]
  local def = M.definition(id)
  local obj = def.objectives[index]
  local target = obj.count or 1
  local before = r.progress[index] or 0
  if before >= target then
    return
  end
  r.progress[index] = math.min(target, before + amount)
  if r.progress[index] >= target then
    state.say(("Objective complete: %s"):format(M.describe(obj, r.progress[index])))
  end
  if M.is_complete(id) then
    state.say(("%s - all objectives met. Report back."):format(def.name or id))
  end
end

---Walk every active quest and let each objective look at the event.
---@param event table { kind, mob, command, zone }
local function advance(event)
  for id, r in pairs(state.quests) do
    if r.status == M.ACTIVE then
      local def = M.definition(id)
      for i, obj in ipairs(def and def.objectives or {}) do
        local hit = false
        if obj.kind == "kill" and event.kind == "kill" then
          hit = obj.mob == nil or obj.mob == event.mob
        elseif obj.kind == "kill_with" and event.kind == "kill" then
          hit = (obj.mob == nil or obj.mob == event.mob)
            and obj.command ~= nil
            and event.command ~= nil
            and event.command:find(obj.command, 1, true) ~= nil
        elseif obj.kind == "clear_zone" and event.kind == "clear_zone" then
          hit = obj.zone == event.zone
        elseif obj.kind == "reach" and event.kind == "reach" then
          hit = obj.zone == event.zone
        end
        if hit then
          credit(id, i, 1)
        end
      end
    end
  end
end

---@param mob table the mob that died
---@param command string the keys that killed it
function M.on_kill(mob, command)
  advance({ kind = "kill", mob = mob.mob or mob.kind, command = command })
end

---@param zone_id string
function M.on_zone_cleared(zone_id)
  advance({ kind = "clear_zone", zone = zone_id })
end

---@param zone_id string
function M.on_zone_entered(zone_id)
  advance({ kind = "reach", zone = zone_id })
end

---Hand in a finished quest and pay out. Rewards are data, so a new reward type
---means a new branch here and nowhere else.
---@param id string
---@return boolean paid
function M.turn_in(id)
  if not M.is_complete(id) then
    return false
  end
  local def = M.definition(id)
  state.quests[id].status = M.TURNED_IN
  local reward = def.reward or {}
  if reward.skills then
    require("vimquest.systems.skills").award(reward.skills, 1)
  end
  if reward.perk_points then
    state.perk_bonus = state.perk_bonus + reward.perk_points
    state.say(("You earn %d perk point%s."):format(reward.perk_points, reward.perk_points == 1 and "" or "s"))
  end
  state.say(("Quest complete: %s"):format(def.name or id))
  return true
end

---@param status string|nil filter, or nil for everything known
---@return table[] list of { id, def, record }
function M.list(status)
  local out = {}
  for id, r in pairs(state.quests) do
    if not status or r.status == status then
      local def = M.definition(id)
      if def then
        table.insert(out, { id = id, def = def, record = r })
      end
    end
  end
  table.sort(out, function(a, b)
    return (a.def.name or a.id) < (b.def.name or b.id)
  end)
  return out
end

---@return table
function M.serialise()
  local out = {}
  for id, r in pairs(state.quests) do
    out[id] = { status = r.status, progress = r.progress, def = r.def }
  end
  return out
end

---@param data table|nil
function M.restore(data)
  state.quests = {}
  for id, r in pairs(data or {}) do
    if type(r) == "table" and type(r.status) == "string" then
      -- JSON turns a sparse array into an object, so {[2]=1} comes back as
      -- {["2"]=1}. Objective indices have to be numbers again or progress on
      -- anything but the first objective would silently reset.
      local progress = {}
      for k, v in pairs(type(r.progress) == "table" and r.progress or {}) do
        local n = tonumber(k)
        if n and type(v) == "number" then
          progress[n] = v
        end
      end
      state.quests[id] = {
        status = r.status,
        progress = progress,
        def = type(r.def) == "table" and r.def or nil,
      }
    end
  end
end

return M
