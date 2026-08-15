-- Perks: spending character levels on permanent changes.
--
-- content/perks.lua declares *what* changes; this file is the only place that
-- knows *how*. Effects are recomputed from scratch whenever the set of owned
-- perks changes, so buying one is never order-dependent and a perk can be
-- rebalanced without migrating anyone's save.

local state = require("vimquest.state")
local config = require("vimquest.config")
local skills = require("vimquest.systems.skills")

local M = {}

---@return table[] every perk in the tree
function M.all()
  return require("vimquest.content.perks")
end

---@param id string
---@return table|nil
function M.get(id)
  for _, perk in ipairs(M.all()) do
    if perk.id == id then
      return perk
    end
  end
  return nil
end

---@param id string
---@return boolean
function M.owned(id)
  return state.perks[id] == true
end

---Points earned across the whole character, from levels and quest rewards.
---@return integer
function M.earned()
  return (skills.character_level() - 1) + state.perk_bonus
end

---@return integer
function M.spent()
  local total = 0
  for id in pairs(state.perks) do
    local perk = M.get(id)
    total = total + (perk and perk.cost or 1)
  end
  return total
end

---@return integer
function M.available()
  return M.earned() - M.spent()
end

---Is this perk's skill requirement met?
---@param perk table
---@return boolean ok, string|nil why not
function M.requirements_met(perk)
  for key, level in pairs(perk.requires or {}) do
    local s = skills.get(key)
    if s.level < level then
      return false, ("needs %s level %d"):format(key, level)
    end
  end
  return true
end

---@param id string
---@return boolean bought, string|nil why not
function M.buy(id)
  local perk = M.get(id)
  if not perk then
    return false, "no such perk"
  end
  if M.owned(id) then
    return false, "already learned"
  end
  local ok, why = M.requirements_met(perk)
  if not ok then
    return false, why
  end
  if M.available() < perk.cost then
    return false, ("needs %d point%s"):format(perk.cost, perk.cost == 1 and "" or "s")
  end
  state.perks[id] = true
  M.apply()
  state.say(("Perk learned: %s"):format(perk.name))
  return true
end

---The combined effect of everything owned, as a flat table.
---@return table
function M.effects()
  local out = { max_hp = 0, stamina_regen = 0, miss_stamina = 0, combo_bonus = 0, xp_multiplier = 0, stamina_cost = {} }
  for _, perk in ipairs(M.all()) do
    if M.owned(perk.id) then
      local e = perk.effects or {}
      out.max_hp = out.max_hp + (e.max_hp or 0)
      out.stamina_regen = out.stamina_regen + (e.stamina_regen or 0)
      out.miss_stamina = out.miss_stamina + (e.miss_stamina or 0)
      out.combo_bonus = out.combo_bonus + (e.combo_bonus or 0)
      out.xp_multiplier = out.xp_multiplier + (e.xp_multiplier or 0)
      for key, cost in pairs(e.stamina_cost or {}) do
        -- The kindest owned perk wins, so perks never fight each other.
        out.stamina_cost[key] = math.min(out.stamina_cost[key] or math.huge, cost)
      end
    end
  end
  return out
end

---Recompute live tunables from the owned set. Called after buying a perk and
---after a save is loaded; safe to call at any time.
function M.apply()
  local e = M.effects()
  local base = config.defaults
  local opts = config.options

  opts.player.stamina_regen = base.player.stamina_regen + e.stamina_regen
  opts.combat.miss_stamina = math.max(0, base.combat.miss_stamina + e.miss_stamina)
  opts.combat.combo_bonus = base.combat.combo_bonus + e.combo_bonus

  opts.stamina_cost = vim.deepcopy(base.stamina_cost)
  for key, cost in pairs(e.stamina_cost) do
    opts.stamina_cost[key] = cost
  end

  state.perk_hp = e.max_hp
  state.perk_xp_multiplier = 1 + e.xp_multiplier
  skills.apply_to_player()
end

---@return table<string, boolean>
function M.serialise()
  return vim.deepcopy(state.perks)
end

---@param data table|nil
function M.restore(data)
  state.perks = {}
  for id, owned in pairs(data or {}) do
    if owned == true and M.get(id) then
      state.perks[id] = true
    end
  end
end

return M
