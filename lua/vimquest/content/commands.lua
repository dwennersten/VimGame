-- The cheatsheet's contents. Pure data: adding a command is a line here.
--
-- A group is unlocked once you have earned any xp in its skill, or as soon as
-- the zone you are standing in contains something that teaches it - so the
-- reference appears exactly when it becomes useful, never as a wall of text.

return {
  {
    title = "Walking",
    basic = true,
    items = {
      { "h j k l", "one cell left/down/up/right - costs 2 stamina each" },
      { "w b e", "forward/back/end of word - nearly free" },
      { "{ }", "jump a paragraph (a blank-ish band of the map)" },
    },
  },
  {
    title = "Blinks",
    basic = true,
    items = {
      { "0 ^ $", "start of line / first solid ground / end of line" },
      { "gg G", "top / bottom of the map" },
      { "f{char}", "dash to the next {char} on this line;  ; repeats, , reverses" },
      { "t{char}", "dash to just before the next {char}" },
    },
  },
  {
    title = "Strikes",
    skill = "operator",
    items = {
      { "x", "stab the character under the cursor - kills grubs (o)" },
      { "dw", "delete to the start of the next word" },
      { "de", "delete to the end of this word" },
      { "cw", "delete the word and start typing in its place" },
      { "dd", "delete the whole line - kills line-wraiths" },
      { "D  d$", "delete from the cursor to the end of the line" },
      { ".", "repeat the last strike - builds the combo meter" },
    },
  },
  {
    title = "Text objects",
    skill = "textobject",
    items = {
      { 'di"', 'delete inside the quotes - kills quoted imps ("imp")' },
      { 'da"', "delete the quotes as well as what is inside them" },
      { "di(", "delete inside the brackets - wounds bracket trolls" },
      { "ca(", "change the brackets and their contents together" },
      { "ciw", "change the word under the cursor, wherever you stand in it" },
      { "", "i = inside,  a = around (takes the delimiters too)" },
    },
  },
  {
    title = "Counts",
    skill = "count",
    items = {
      { "3dw", "one strike, three words - kills swarms" },
      { "5j  10l", "travel far for a single keypress" },
      { "2ci(", "reach through one pair of brackets into the next" },
      { "", "a count in front of a command multiplies it" },
    },
  },
  {
    title = "Out of character",
    basic = true,
    items = {
      { "<F1>", "journal - everything said this run" },
      { "<F2>", "pause / resume the world" },
      { "<F3>", "this cheatsheet" },
      { "<Esc><Esc>", "leave the world" },
    },
  },
}
