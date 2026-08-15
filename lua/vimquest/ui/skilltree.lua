-- The skill tree (<F5>).
--
-- Perk points come from character levels and quest rewards; a perk is bought
-- once and kept forever. The tree is data in content/perks.lua - this only
-- renders it and asks systems/perks.lua to spend the point.

local menu = require("vimquest.ui.menu")
local perks = require("vimquest.systems.perks")
local skills = require("vimquest.systems.skills")
local state = require("vimquest.state")

local M = {}

M.current = nil

local function build()
  local items = {}
  for _, perk in ipairs(perks.all()) do
    local owned = perks.owned(perk.id)
    local ok, why = perks.requirements_met(perk)
    local affordable = perks.available() >= perk.cost
    local hint
    if owned then
      hint = "learned"
    elseif not ok then
      hint = why
    elseif not affordable then
      hint = ("%d points"):format(perk.cost)
    else
      hint = ("%d point%s"):format(perk.cost, perk.cost == 1 and "" or "s")
    end
    table.insert(items, {
      label = ("%-14s %s"):format(perk.name, perk.desc),
      hint = hint,
      enabled = not owned and ok and affordable,
      value = perk,
    })
  end

  local header = {
    ("Perk points   %d unspent   (%d earned, %d spent)"):format(perks.available(), perks.earned(), perks.spent()),
    "",
    "A point arrives with every second skill level, and quests hand them out.",
    "Nothing here is required to finish the game - they make the road kinder.",
    "",
  }
  vim.list_extend(header, skills.report())

  return {
    header = header,
    items = items,
    title = ("Skill tree - level %d"):format(state.player and state.player.level or 1),
    footer = "j / k choose   -   <CR> learn   -   <Esc> close",
  }
end

function M.close()
  if M.current then
    local c = M.current
    M.current = nil
    c.close()
  end
end

function M.open()
  if M.current then
    return
  end
  local opts = build()
  opts.on_select = function(item, m)
    local ok, why = perks.buy(item.value.id)
    if not ok and why then
      state.say(("%s: %s"):format(item.value.name, why))
    end
    m.set(build())
  end
  opts.on_close = function()
    M.current = nil
  end
  M.current = menu.open(opts)
end

function M.toggle()
  if M.current then
    M.close()
  else
    M.open()
  end
end

return M
