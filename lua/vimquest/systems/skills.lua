-- Skill-by-use progression.
--
-- There is no abstract XP bar. The thing you practise is the thing that levels:
-- word motions raise Motion, operators raise Operator, text objects raise
-- Text-object, counts raise Count. Mobs declare what they teach (see
-- content/mobs.lua), so adding a skill-granting mob never touches this file.

local state = require("vimquest.state")
local config = require("vimquest.config")

local M = {}

---Display order and descriptions. Adding a key here is all a new skill needs.
M.definitions = {
  { key = "motion", name = "Motion", about = "w b e, counts, blinks" },
  { key = "operator", name = "Operator", about = "x d c and their motions" },
  { key = "textobject", name = "Text-object", about = 'iw i" i( a( ...' },
  { key = "count", name = "Count", about = "3dw and other multipliers" },
}

---XP required to advance from `level` to `level + 1`.
---@param level integer
---@return integer
function M.level_cost(level)
  local cfg = config.options.skills
  return cfg.base_level_xp + (level - 1) * cfg.level_xp_step
end

---Get (creating if needed) one skill record.
---@param key string
---@return table {xp:number, level:integer}
function M.get(key)
  local s = state.skills[key]
  if not s then
    s = { xp = 0, level = 1 }
    state.skills[key] = s
  end
  return s
end

---Ensure every defined skill exists, so the UI never has holes.
function M.ensure()
  for _, def in ipairs(M.definitions) do
    M.get(def.key)
  end
end

---@param key string
---@return string
local function display_name(key)
  for _, def in ipairs(M.definitions) do
    if def.key == key then
      return def.name
    end
  end
  return key
end

---Character level is the average progress across all skills, so a well-rounded
---player levels faster than one who only ever spams the same operator.
---@return integer
function M.character_level()
  local gained = 0
  for _, def in ipairs(M.definitions) do
    gained = gained + (M.get(def.key).level - 1)
  end
  return 1 + math.floor(gained / 2)
end

---Recompute the player's derived stats from skill levels.
function M.apply_to_player()
  local p = state.player
  if not p then
    return
  end
  local level = M.character_level()
  local bonus = (level - 1) * config.options.skills.hp_per_level
  local base = config.options.player.max_hp
  p.level = level
  -- state.perk_hp is maintained by systems/perks.lua. Reading it rather than
  -- requiring that module keeps skills free of a dependency cycle.
  p.max_hp = base + bonus + (state.perk_hp or 0)
  p.hp = math.min(p.hp, p.max_hp)
end

---Award xp across several skills at once.
---@param grants table<string, number> skill key -> xp
---@param multiplier number|nil combo multiplier
---@return integer total xp actually awarded
function M.award(grants, multiplier)
  multiplier = (multiplier or 1) * (state.perk_xp_multiplier or 1)
  local total = 0
  local levelled = {}

  for key, amount in pairs(grants or {}) do
    local gain = math.max(1, math.floor(amount * multiplier + 0.5))
    local s = M.get(key)
    s.xp = s.xp + gain
    total = total + gain
    while s.xp >= M.level_cost(s.level) do
      s.xp = s.xp - M.level_cost(s.level)
      s.level = s.level + 1
      table.insert(levelled, ("%s reaches level %d"):format(display_name(key), s.level))
    end
  end

  if state.player then
    state.player.xp = state.player.xp + total
  end

  if #levelled > 0 then
    local before = state.player and state.player.level or 1
    M.apply_to_player()
    for _, line in ipairs(levelled) do
      state.say(line)
    end
    local after = state.player and state.player.level or 1
    if after > before then
      state.say(("You are now level %d. Max health %d."):format(after, state.player.max_hp))
    end
  end

  return total
end

---Serialise for the save file.
---@return table
function M.serialise()
  M.ensure()
  local out = {}
  for key, s in pairs(state.skills) do
    out[key] = { xp = s.xp, level = s.level }
  end
  return out
end

---Restore from a save file, ignoring skills this build no longer knows about.
---@param data table|nil
function M.restore(data)
  state.skills = {}
  for key, s in pairs(data or {}) do
    if type(s) == "table" then
      state.skills[key] = { xp = tonumber(s.xp) or 0, level = math.max(1, tonumber(s.level) or 1) }
    end
  end
  M.ensure()
end

---Lines for a skill report, used by the cheatsheet and the zone-clear panel.
---@return string[]
function M.report()
  M.ensure()
  local lines = {}
  for _, def in ipairs(M.definitions) do
    local s = M.get(def.key)
    local cost = M.level_cost(s.level)
    local filled = math.floor((s.xp / cost) * 10 + 0.5)
    filled = math.max(0, math.min(10, filled))
    table.insert(
      lines,
      ("  %-12s Lv %-3d [%s%s] %d/%d   %s"):format(
        def.name,
        s.level,
        string.rep("#", filled),
        string.rep("-", 10 - filled),
        s.xp,
        cost,
        def.about
      )
    )
  end
  return lines
end

return M
