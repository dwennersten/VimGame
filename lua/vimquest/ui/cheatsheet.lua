-- Always-available command reference (<F3>).
--
-- Dan chose "show me the commands" over discovery-by-experiment, so this is
-- never hidden behind progress. What it *does* gate is noise: a group only
-- appears once its skill is in use or the current zone contains something that
-- teaches it, and locked groups show what will open them.
--
-- Like every panel it freezes the world. Reading is never timed.

local panel = require("vimquest.ui.panel")
local state = require("vimquest.state")
local skills = require("vimquest.systems.skills")
local commands = require("vimquest.content.commands")

local M = {}

M.current = nil

---Does anything in the current zone teach this skill?
---@param key string
---@return boolean
local function zone_teaches(key)
  for _, m in ipairs(state.mobs) do
    if (m.teaches or {})[key] then
      return true
    end
  end
  return false
end

---@param group table
---@return boolean
local function unlocked(group)
  if group.basic or not group.skill then
    return true
  end
  local s = skills.get(group.skill)
  return s.level > 1 or s.xp > 0 or zone_teaches(group.skill)
end

---@return string[]
function M.lines()
  local out = {}
  local locked = {}

  for _, group in ipairs(commands) do
    if unlocked(group) then
      table.insert(out, group.title)
      for _, item in ipairs(group.items) do
        if item[1] == "" then
          table.insert(out, ("      %s"):format(item[2]))
        else
          table.insert(out, ("  %-12s %s"):format(item[1], item[2]))
        end
      end
      table.insert(out, "")
    else
      table.insert(locked, group.title)
    end
  end

  if #locked > 0 then
    table.insert(out, "Not yet learned: " .. table.concat(locked, ", "))
    table.insert(out, "These open when you meet something that teaches them.")
    table.insert(out, "")
  end

  table.insert(out, "Skills")
  vim.list_extend(out, skills.report())

  -- Whatever stands in this zone, and the command it answers to.
  local seen, roster = {}, {}
  for _, m in ipairs(state.mobs) do
    if m.alive and not seen[m.kind] then
      seen[m.kind] = true
      table.insert(roster, ("  %-16s %s"):format(m.name, m.hint or "?"))
    end
  end
  if #roster > 0 then
    table.insert(out, "")
    table.insert(out, "Still standing in " .. (state.zone and state.zone.name or "this zone"))
    vim.list_extend(out, roster)
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
    title = "Cheatsheet",
    footer = "<F3> or <Esc> to close   -   the world is frozen while this is open",
    close_keys = { "<F3>", "<Esc>", "q", "<CR>" },
    on_close = function()
      M.current = nil
    end,
  })
end

return M
