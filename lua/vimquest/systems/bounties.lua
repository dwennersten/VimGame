-- Radiant bounties: the ten-minute session shape.
--
-- A bounty is a quest generated from the mob roster, so it needs no authoring
-- and never runs out. Its definition is stored on the quest record itself,
-- which is what lets a bounty survive a save without being written down in
-- content/quests.lua.
--
-- The board is seeded per day, so it is stable inside a session and refreshes
-- tomorrow. S4 will bias this toward the commands the player fumbles most; the
-- selection is deliberately isolated in `pick` so that stays a small change.

local state = require("vimquest.state")
local mobs = require("vimquest.content.mobs")
local quests = require("vimquest.systems.quests")

local M = {}

M.BOARD_SIZE = 3

---Roster keys in a stable order, so a seed picks the same board twice.
---@return string[]
local function roster_keys()
  local keys = {}
  for key in pairs(mobs.roster) do
    table.insert(keys, key)
  end
  table.sort(keys)
  return keys
end

---@return integer
local function today()
  return math.floor(os.time() / 86400)
end

---Which mobs today's board asks for.
---@param count integer
---@return string[]
local function pick(count)
  local keys = roster_keys()
  local seed = today()
  local out, used = {}, {}
  for i = 0, count - 1 do
    -- A tiny deterministic shuffle: no dependency on math.randomseed, which is
    -- global state the game has no business touching.
    local idx = ((seed * 7 + i * 31) % #keys) + 1
    local tries = 0
    while used[idx] and tries < #keys do
      idx = (idx % #keys) + 1
      tries = tries + 1
    end
    used[idx] = true
    table.insert(out, keys[idx])
  end
  return out
end

---Build the contract for one mob kind.
---@param key string roster key
---@return table quest definition
function M.contract(key)
  local def = mobs.roster[key]
  local count = def.kind == "swarm" and 2 or 4
  local xp = {}
  for skill, amount in pairs(def.teaches or {}) do
    xp[skill] = amount * count
  end
  return {
    id = "bounty:" .. key,
    name = ("Bounty: %s"):format(def.name),
    bounty = true,
    summary = ("Clear %d %s from the wood."):format(count, def.name),
    objectives = {
      {
        kind = "kill",
        mob = key,
        count = count,
        text = ("slay %d %s  (%s)"):format(count, def.name, def.hint or "?"),
      },
    },
    reward = { skills = xp },
    on_offer = {
      ("The board has work: %d %s, still standing."):format(count, def.name),
      "",
      def.hint or "",
      "",
      "Take it or leave it. The board does not mind either way.",
    },
    on_complete = {
      "Paid. The board already has more.",
    },
  }
end

---Today's board, minus anything already taken or finished.
---@return table[] quest definitions
function M.board()
  local out = {}
  for _, key in ipairs(pick(M.BOARD_SIZE)) do
    local def = M.contract(key)
    local status = quests.status(def.id)
    if status ~= quests.ACTIVE and status ~= quests.TURNED_IN then
      table.insert(out, def)
    end
  end
  return out
end

---Bounties the player is currently carrying.
---@return table[] entries from quests.list
function M.active()
  local out = {}
  for _, entry in ipairs(quests.list(quests.ACTIVE)) do
    if entry.def.bounty then
      table.insert(out, entry)
    end
  end
  return out
end

---A finished bounty can be handed in anywhere, unlike a quest with a giver.
---@return integer paid
function M.turn_in_all()
  local paid = 0
  for _, entry in ipairs(M.active()) do
    if quests.is_complete(entry.id) and quests.turn_in(entry.id) then
      paid = paid + 1
    end
  end
  if paid > 0 then
    state.say(("%d bount%s paid out."):format(paid, paid == 1 and "y" or "ies"))
  end
  return paid
end

return M
