-- NPC conversations.
--
-- An NPC carries a `dialogue` table of nodes; a node has text and a list of
-- choices, and a choice can walk to another node and/or fire an action. Both
-- are pure data, so writing an NPC never means writing code.
--
--   dialogue = {
--     start = {
--       text = { "..." },
--       choices = {
--         { label = "What is out there?", to = "wood" },
--         { label = "I need work.",       to = "work", action = { offer = "cut_back_the_rot" } },
--         { label = "Nothing.", },                      -- no `to` ends the talk
--       },
--     },
--   }
--
-- Actions, all optional and all data:
--   offer    = "<quest id>"   offer it; the choice is hidden once accepted
--   turn_in  = "<quest id>"   hand it in; the choice only appears when complete
--   board    = true           open the bounty board
--   perks    = true           open the skill tree
--   heal     = true           restore health and stamina
--
-- Conditions on a choice, checked before it is shown:
--   requires_quest = "<id>"        only while that quest is active
--   requires_done  = "<id>"        only once that quest is handed in
--   hidden_if_done = "<id>"        hide once that quest is handed in

local menu = require("vimquest.ui.menu")
local state = require("vimquest.state")
local quests = require("vimquest.systems.quests")

local M = {}

M.current = nil

---@param choice table
---@return boolean
local function visible(choice)
  local a = choice.action or {}
  if choice.requires_quest and quests.status(choice.requires_quest) ~= quests.ACTIVE then
    return false
  end
  if choice.requires_done and quests.status(choice.requires_done) ~= quests.TURNED_IN then
    return false
  end
  if choice.hidden_if_done and quests.status(choice.hidden_if_done) == quests.TURNED_IN then
    return false
  end
  if a.offer then
    -- Nothing is offered twice.
    local status = quests.status(a.offer)
    return status ~= quests.ACTIVE and status ~= quests.TURNED_IN
  end
  if a.turn_in then
    return quests.is_complete(a.turn_in)
  end
  return true
end

---@param node table
---@return table[] menu items
local function items_for(node)
  local out = {}
  for _, choice in ipairs(node.choices or {}) do
    if visible(choice) then
      table.insert(out, { label = choice.label, value = choice })
    end
  end
  if #out == 0 then
    table.insert(out, { label = "(leave)", value = { label = "(leave)" } })
  end
  return out
end

---Run a choice's action. Returns a node id to jump to, or nil.
---@param choice table
---@return string|nil
local function act(choice)
  local a = choice.action or {}
  if a.offer then
    local def = quests.definition(a.offer)
    quests.accept(a.offer)
    if def and def.on_offer then
      state.say(def.on_offer)
    end
  end
  if a.turn_in then
    local def = quests.definition(a.turn_in)
    if quests.turn_in(a.turn_in) and def and def.on_complete then
      state.say(def.on_complete)
    end
  end
  if a.heal and state.player then
    state.player.hp = state.player.max_hp
    state.player.stamina = state.player.max_stamina
    state.say("You are made whole again.")
  end
  if a.board then
    M.close()
    require("vimquest.ui.board").open()
    return nil
  end
  if a.perks then
    M.close()
    require("vimquest.ui.skilltree").open()
    return nil
  end
  return choice.to
end

---@param npc table
---@param node_id string
local function show(npc, node_id)
  local node = (npc.dialogue or {})[node_id]
  if not node then
    M.close()
    return
  end

  local header = {}
  vim.list_extend(header, type(node.text) == "table" and node.text or { node.text or "" })
  state.say(header)

  local opts = {
    header = header,
    items = items_for(node),
    title = npc.name or "someone",
    footer = "j / k choose   -   <CR> say it   -   <Esc> walk away",
    on_select = function(item)
      local next_id = act(item.value)
      if next_id then
        show(npc, next_id)
      else
        M.close()
      end
    end,
    on_close = function()
      M.current = nil
    end,
  }

  if M.current then
    -- Same panel, new node: the conversation does not blink between lines.
    M.current.set(opts)
  else
    M.current = menu.open(opts)
  end
end

---@param npc table
function M.start(npc)
  if M.current then
    return
  end
  show(npc, npc.start or "start")
end

function M.close()
  if M.current then
    local c = M.current
    M.current = nil
    c.close()
  end
end

return M
