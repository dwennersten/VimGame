-- The quest log (<F4>).
--
-- Read-only, so it is a plain panel rather than a menu. Like every panel it
-- freezes the world: checking what you are supposed to be doing is never
-- something the game punishes.

local panel = require("vimquest.ui.panel")
local quests = require("vimquest.systems.quests")

local M = {}

M.current = nil

---@return string[]
function M.lines()
  local out = {}
  local active = quests.list(quests.ACTIVE)

  if #active == 0 then
    table.insert(out, "Nothing is asked of you.")
    table.insert(out, "")
    table.insert(out, "Quests come from people: walk into an NPC in Coldbuffer and talk.")
    table.insert(out, "The bounty board there always has work, whatever else is going on.")
  else
    table.insert(out, "Active")
    table.insert(out, "")
    for _, entry in ipairs(active) do
      local done = quests.is_complete(entry.id)
      table.insert(out, ("  %s%s"):format(entry.def.name, done and "   -   ready to hand in" or ""))
      if entry.def.summary then
        table.insert(out, "    " .. entry.def.summary)
      end
      for i, obj in ipairs(entry.def.objectives or {}) do
        table.insert(out, "      " .. quests.describe(obj, entry.record.progress[i] or 0))
      end
      table.insert(out, "")
    end
  end

  local done = quests.list(quests.TURNED_IN)
  if #done > 0 then
    table.insert(out, "Finished")
    table.insert(out, "")
    for _, entry in ipairs(done) do
      table.insert(out, "  " .. entry.def.name)
    end
  end

  return out
end

function M.close()
  if M.current then
    M.current.close()
    M.current = nil
  end
end

function M.toggle()
  if M.current then
    M.close()
    return
  end
  M.current = panel.open({
    lines = M.lines(),
    title = "Quest log",
    footer = "<F4> or <Esc> to close",
    close_keys = { "<F4>", "<Esc>", "q", "<CR>" },
    on_close = function()
      M.current = nil
    end,
  })
end

return M
