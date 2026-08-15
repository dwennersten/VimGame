-- Zone 0 - The Awakening
--
-- Teaches: you are the cursor. hjkl to move, walls block, counts and word
-- motions are cheaper than mashing. One slow hostile appears near the end so
-- the real-time pressure is introduced gently.
--
-- Authoring notes: every row must be the same length. '#' is solid. Legend
-- characters are replaced by floor at load time.

return {
  id = "00_awakening",
  name = "The Awakening",
  solid = "#",
  floor = ".",

  map = {
    "################################################################",
    "#..............#.........................#.....................#",
    "#..THE.CRYPT...#.........................#....THE.LONG.HALL....#",
    "#..............#.........................#.....................#",
    "#....@....1....+.........2...............#.........3...........#",
    "#..............#.........................#.....................#",
    "#..............#....#####........#####...#.....................#",
    "#..............#....#...............#....+.....................#",
    "################....#...............#....#############.#########",
    "#....................#...........#.......#.............#.......#",
    "#....................#...........#.......#....g........+...4...#",
    "#....................#...........#.......#.............#.......#",
    "#....................#############.......#############.#.......#",
    "#........................................#.............#...5...#",
    "#........................................#.............#.......#",
    "################################################################",
  },

  legend = {
    ["@"] = { type = "spawn" },
    ["+"] = { type = "trigger", text = "A doorway. Walk through it.", leaves = "." },
    ["1"] = {
      type = "trigger",
      text = "You wake as a cursor. h left, j down, k up, l right. Walls will not yield.",
    },
    ["2"] = {
      type = "trigger",
      text = "Watch your stamina bar: mashing hjkl drains it. Try w and b to skip word-wise, or 5j for five rows at once.",
    },
    ["3"] = {
      type = "trigger",
      text = "Long halls are for long motions. 0 goes to line start, $ to line end, gg to the top, G to the bottom.",
    },
    ["4"] = {
      type = "trigger",
      text = "Something moves in the vault. It is slow. Keep distance - in S2 you will learn to strike it with x and dw.",
    },
    ["5"] = {
      type = "trigger",
      text = "You have survived The Awakening. <Esc><Esc> to leave. More zones arrive in the next build.",
    },
    ["g"] = {
      type = "entity",
      kind = "rot_shambler",
      name = "rot shambler",
      glyph = "g",
      behaviour = "chaser",
      speed = 9, -- moves once every 9 ticks (~0.9s)
      hp = 3,
    },
  },

  intro = "The Corrupted Buffer stirs. Move with h j k l.",
}
