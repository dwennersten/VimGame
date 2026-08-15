-- Heads-up display.
--   winbar     -> vitals (HP, stamina, level, zone)
--   statusline -> message log + current hint
--
-- Note: winbar/statusline are statusline-syntax, so literal '%' must be escaped.

local state = require("vimquest.state")
local config = require("vimquest.config")

local M = {}

---@param value number
---@param max number
---@param width integer
---@return string
local function bar(value, max, width)
  local filled = 0
  if max > 0 then
    filled = math.floor((value / max) * width + 0.5)
  end
  filled = math.max(0, math.min(width, filled))
  return string.rep("#", filled) .. string.rep("-", width - filled)
end

---Escape statusline metacharacters in dynamic text.
---@param s string
---@return string
local function esc(s)
  return (s:gsub("%%", "%%%%"))
end

---@param hp number
---@param max number
---@return string highlight group name
local function hp_hl(hp, max)
  local ratio = max > 0 and (hp / max) or 0
  if ratio <= 0.3 then
    return "VimQuestHudBad"
  elseif ratio <= 0.6 then
    return "VimQuestHudWarn"
  end
  return "VimQuestHudGood"
end

function M.render()
  local win = state.win
  local p = state.player
  if not win or not p or not vim.api.nvim_win_is_valid(win) then
    return
  end
  if not config.options.ui.winbar then
    return
  end

  local w = config.options.ui.bar_width
  local stam_hl = p.stamina <= 0 and "VimQuestHudBad" or "VimQuestHudDim"

  -- Combat readouts only appear in zones that have something to fight.
  local foes = ""
  if #state.mobs > 0 then
    local alive = 0
    for _, m in ipairs(state.mobs) do
      if m.alive then
        alive = alive + 1
      end
    end
    foes = "%#" .. (alive > 0 and "VimQuestHudWarn" or "VimQuestHudGood") .. "#  FOES " .. alive
  end
  local combo = state.combo > 1 and ("%#VimQuestXp#  COMBO x" .. state.combo) or ""

  -- Unspent perk points nag quietly until they are spent.
  local points = require("vimquest.systems.perks").available()
  local unspent = points > 0 and ("%#VimQuestHudGood#  PERKS " .. points) or ""

  local parts = {
    "%#VimQuestHudText# VQ ",
    "%#" .. hp_hl(p.hp, p.max_hp) .. "#HP [" .. bar(p.hp, p.max_hp, w) .. "] ",
    string.format("%d/%d ", p.hp, p.max_hp),
    "%#" .. stam_hl .. "# STA [" .. bar(p.stamina, p.max_stamina, w) .. "] ",
    "%#VimQuestHudText# LVL " .. p.level .. "  XP " .. p.xp,
    foes,
    combo,
    unspent,
    "%#VimQuestHudDim#   " .. esc(state.zone and state.zone.name or ""),
    state.paused and "%#VimQuestHudWarn#   [PAUSED]" or "",
    "%#VimQuestHudDim#   <F3> help  <F4> quests  <F5> perks  <Esc><Esc> quit",
  }
  vim.wo[win].winbar = table.concat(parts)

  local msg = state.messages[#state.messages] or ""
  local tail = #state.journal > 0 and ("%#VimQuestHudDim#   [" .. #state.journal .. " in journal - <F1>]") or ""
  vim.wo[win].statusline = "%#VimQuestHudText# " .. esc(msg) .. tail
end

return M
