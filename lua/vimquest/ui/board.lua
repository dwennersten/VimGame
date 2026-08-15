-- The bounty board.
--
-- Radiant contracts, taken and paid at the board itself. This is the
-- ten-minute session shape from DESIGN.md: pick one, go, come back.

local menu = require("vimquest.ui.menu")
local bounties = require("vimquest.systems.bounties")
local quests = require("vimquest.systems.quests")

local M = {}

M.current = nil

local function build()
  local items = {}

  for _, entry in ipairs(bounties.active()) do
    local done = quests.is_complete(entry.id)
    local obj = entry.def.objectives[1]
    items[#items + 1] = {
      label = entry.def.name,
      hint = done and "ready to claim" or quests.describe(obj, entry.record.progress[1] or 0),
      value = { claim = done and entry.id or nil },
      enabled = done,
    }
  end

  for _, def in ipairs(bounties.board()) do
    items[#items + 1] = {
      label = def.name,
      hint = def.objectives[1].text,
      value = { take = def },
    }
  end

  return {
    header = {
      "Contracts, unsigned and unsentimental.",
      "",
      "Take what you like. A bounty pays into the skill it drills, so the",
      "board is also the fastest way to level something you are bad at.",
    },
    items = items,
    title = "The Bounty Board",
    footer = "j / k choose   -   <CR> take or claim   -   <Esc> step away",
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
    local v = item.value or {}
    if v.take then
      quests.accept(v.take.id, v.take)
      require("vimquest.state").say(v.take.on_offer or {})
    elseif v.claim then
      local def = quests.definition(v.claim)
      if quests.turn_in(v.claim) and def and def.on_complete then
        require("vimquest.state").say(def.on_complete)
      end
    end
    m.set(build())
  end
  opts.on_close = function()
    M.current = nil
  end
  M.current = menu.open(opts)
end

return M
