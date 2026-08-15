-- Mob roster.
--
-- A text-mob IS buffer text. You kill it by performing the correct vim edit on
-- it; the engine watches the buffer for changes rather than parsing keystrokes,
-- so any equivalent keystroke path counts. That is what real fluency looks like.
--
-- Fields
--   text      default body of the mob as it appears in the map (ASCII only)
--   weakness  Lua patterns matched against the TAIL of the keys pressed since
--             the last buffer change. "dw" matches "lllldw" but not "x".
--             Anything that is not a weakness is a miss: the map repaints and
--             the strike costs stamina, but nothing is corrupted.
--   teaches   skill -> xp awarded on a kill (see systems/skills.lua)
--   xp        base xp, multiplied by the combo meter
--   hint      one-line reference, shown in the <F3> cheatsheet
--
-- Zones reference these by key; see CONTENT.md for the legend syntax.

local M = {}

M.roster = {
  grub = {
    kind = "grub",
    name = "rot grub",
    text = "o",
    hl = "VimQuestMobGrub",
    weakness = { "x" },
    teaches = { operator = 4 },
    xp = 4,
    hint = 'x  -  stab the single character under the cursor',
  },

  word_mob = {
    kind = "word_mob",
    name = "blight-word",
    text = "rot",
    hl = "VimQuestMobWord",
    weakness = { "d[we]", "c[we]" },
    teaches = { operator = 5, motion = 3 },
    xp = 7,
    hint = 'dw / de  -  delete a word; cw changes it (operator + motion)',
  },

  quoted_imp = {
    kind = "quoted_imp",
    name = "quoted imp",
    text = '"imp"',
    hl = "VimQuestMobImp",
    weakness = { '[dc]i"', '[dc]a"' },
    teaches = { textobject = 10 },
    xp = 12,
    hint = 'di" / ci"  -  inside the quotes;  da" takes the quotes too',
  },

  bracket_troll = {
    kind = "bracket_troll",
    name = "bracket troll",
    text = "(troll)",
    hl = "VimQuestMobTroll",
    weakness = { "[dc][ia]%(", "[dc][ia]%)", "[dc][ia]b" },
    teaches = { textobject = 12 },
    xp = 14,
    hint = 'di( / ca(  -  i = inside the brackets, a = brackets and all',
  },

  line_wraith = {
    kind = "line_wraith",
    name = "line-wraith",
    text = "the whole line is wrong",
    hl = "VimQuestMobWraith",
    weakness = { "dd", "d%$", "D", "cc", "C", "S" },
    teaches = { operator = 14 },
    xp = 16,
    hint = "dd  -  delete the whole line;  D / d$ delete to end of line",
  },

  swarm = {
    kind = "swarm",
    name = "rot swarm",
    text = "rot mold rip",
    hl = "VimQuestMobWord",
    weakness = { "3d[we]", "3c[we]", "d3[we]", "c3[we]" },
    teaches = { count = 12, operator = 4, motion = 4 },
    xp = 20,
    hint = "3dw  -  a count multiplies a command; three words in one strike",
  },
}

---Resolve a roster key into a fresh mob definition.
---@param key string
---@return table|nil
function M.get(key)
  local def = M.roster[key]
  return def and vim.deepcopy(def) or nil
end

return M
