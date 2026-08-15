-- Zone 0 - The Awakening
--
-- Teaches: you are the cursor. hjkl to move, walls block, counts and word
-- motions are cheaper than mashing. One slow hostile appears near the end so
-- real-time pressure is introduced gently. Exit is the '>' portal in the vault.
--
-- Authoring notes: every row must be the same length. '#' is solid. Legend
-- characters are replaced by floor at load time unless they set `leaves`.

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
    "#........................................#.............#..5.>..#",
    "#........................................#.............#.......#",
    "################################################################",
  },

  legend = {
    ["@"] = { type = "spawn" },

    ["1"] = {
      type = "trigger",
      title = "You are the cursor",
      text = {
        "You wake as a cursor in a rotting text realm.",
        "",
        "  h   left        j   down",
        "  k   up          l   right",
        "",
        "Walls (#) will not yield. Floor (.) will.",
        "Walk east through the doorway to continue.",
      },
    },

    ["2"] = {
      type = "trigger",
      title = "Stamina - why mashing kills you",
      text = {
        "Every h/j/k/l press costs 2 stamina. Bigger motions cost almost nothing.",
        "When stamina hits zero you start losing health, so learn to travel cheaply:",
        "",
        "  w   forward one word        b   back one word",
        "  e   end of word             5j  down five rows at once",
        "",
        "A count before a motion repeats it: 3w, 10l, 4k.",
        "Try crossing this chamber with w and a count instead of holding l.",
      },
    },

    ["3"] = {
      type = "trigger",
      title = "The Long Hall - long motions",
      text = {
        "Long halls are for long motions.",
        "",
        "  0    jump to the start of the line",
        "  $    jump to the end of the line",
        "  ^    first non-blank on the line",
        "  gg   top of the map        G    bottom of the map",
        "",
        "These are blinks: they cross ground instantly for almost no stamina.",
        "They fail against solid rock - a blink into a wall simply does not land.",
        "Head south through the door, then west into the vault.",
      },
    },

    ["4"] = {
      type = "trigger",
      title = "Something is in the vault",
      text = {
        "A rot shambler (g) hunts you here. It is slow, and it cannot be killed yet.",
        "",
        "Keep your distance and keep your stamina up. Contact costs health;",
        "dying only returns you to the shrine, so this is a safe place to practise.",
        "",
        "In The Rotwood you will learn to strike: x, dw, di\" and ca( become attacks.",
        "",
        "The way out is the portal ( > ) below. Step onto it to finish the zone.",
      },
    },

    ["5"] = {
      type = "trigger",
      title = "The portal",
      text = {
        "The portal ( > ) is one step east of you.",
        "Step onto it when you are ready to leave The Awakening.",
        "",
        "Press <F1> at any time to re-read everything said in this run.",
      },
    },

    [">"] = {
      type = "exit",
      leaves = ">",
      text = "You step onto the portal. The Awakening releases you.",
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

  brief = {
    "The Corrupted Buffer stirs.",
    "",
    "You are the cursor. The text is the world.",
    "",
    "  h j k l    move                     <F1>   journal (re-read everything)",
    "  w b e      word motions (cheap)     <F2>   pause",
    "  0 $ gg G   blinks                   <Esc><Esc>   leave the world",
    "",
    "Mashing h/j/k/l drains stamina and eventually your health.",
    "Signposts along the way will explain the rest - nothing is timed while you read.",
    "",
    "Goal: reach the portal ( > ) in the vault at the far south-east.",
  },

  intro = "The Corrupted Buffer stirs. Move with h j k l.",
}
