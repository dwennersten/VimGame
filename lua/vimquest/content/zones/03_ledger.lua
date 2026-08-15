-- Zone 3 - The Long Ledger
--
-- Teaches: line anchors and character search under pressure. Four long
-- corridors, with the stairs between them at alternating ends so crossing on
-- hjkl is punishing and 0 / $ is obvious. The mobs are their own landmarks -
-- f" dashes you to the next imp, f( to the next troll - which is the lesson.
--
-- Authoring notes: every row is 76 characters. Legend keys are lowercase and
-- digits; labels are uppercase, so they can never collide.

return {
  id = "03_ledger",
  name = "The Long Ledger",
  solid = "#",
  floor = ".",
  combat = true,

  map = {
    "############################################################################",
    "#..THE.LONG.LEDGER.........................................................#",
    "#..........................................................................#",
    "#....@.....1...............................................................#",
    "#..........................................................................#",
    "######################################################################.#####",
    "#..........................................................................#",
    "#...2............qqqqq...................ttttttt...............qqqqq.......#",
    "#..........................................................................#",
    "######.#####################################################################",
    "#..........................................................................#",
    "#...3....rrr.............................mmmm....................bbbbbb....#",
    "#..........................................................................#",
    "######################################################################.#####",
    "#..........................................................................#",
    "#...4.......o.................o.....................o.................>....#",
    "#..........................................................................#",
    "############################################################################",
  },

  legend = {
    ["@"] = { type = "spawn" },

    ["o"] = { type = "mob", mob = "grub" },
    ["r"] = { type = "mob", mob = "word_mob", text = "rot" },
    ["m"] = { type = "mob", mob = "word_mob", text = "mold", name = "mold-word" },
    ["b"] = { type = "mob", mob = "word_mob", text = "ledger", name = "ledger-word" },
    ["q"] = { type = "mob", mob = "quoted_imp" },
    ["t"] = { type = "mob", mob = "bracket_troll" },

    ["1"] = {
      type = "trigger",
      title = "The Ledger - line anchors",
      text = {
        "The Ledger is long on purpose. Walking it with l will exhaust you before",
        "you reach the end of the first line.",
        "",
        "    0     jump to the very start of the line",
        "    ^     jump to the first thing that is not empty floor",
        "    $     jump to the very end of the line",
        "",
        "These are blinks: instant, and nearly free. They stop at rock, so a $",
        "into a wall simply does not land.",
        "",
        "The stairs down are at the far right of this corridor. Use $ to get there.",
      },
    },

    ["2"] = {
      type = "trigger",
      title = "Character search - f and ;",
      text = {
        "Look along this corridor. The things standing in it are their own",
        "landmarks, and you can dash straight to them:",
        "",
        '    f"    dash to the next "  - the mouth of the nearest imp cage',
        "    f(    dash to the next (  - a bracket troll",
        "    ;     do that again, further along",
        "    ,     do it backwards",
        "    t(    dash to just *before* the next (",
        "",
        'So: f" then di" empties an imp without you ever counting a column.',
        "That pair - dash, then strike - is most of what fast editing is.",
        "",
        "The stairs down are at the far LEFT this time. 0 will take you there.",
      },
    },

    ["3"] = {
      type = "trigger",
      title = "Top and bottom",
      text = {
        "Three blight-words share this corridor, and the last one is a long way",
        "east. f is for landmarks on a line; these are for the whole map:",
        "",
        "    gg    the top of the map",
        "    G     the bottom of the map",
        "    5G    line 5, exactly",
        "",
        "A count in front of a motion multiplies it, and that works on everything",
        "you know: 3w, 10l, 4k, 2f( - the second bracket, not the first.",
        "",
        "Try 2f( in the corridor above if you want to see it.",
      },
    },

    ["4"] = {
      type = "trigger",
      title = "The last line",
      text = {
        "Three grubs and the way out, spread along one very long line.",
        "",
        "There is a quiet trick here: after you kill the first grub with x, you",
        "can dash to the next one and press . - the dot repeats your last strike,",
        "and repeated strikes build a combo that multiplies what you learn.",
        "",
        "The portal ( > ) is at the far east. $ will very nearly land you on it.",
      },
    },

    [">"] = {
      type = "exit",
      leaves = ">",
      to = "02_coldbuffer",
      text = "The ledger closes. The road back to Coldbuffer opens.",
    },
  },

  brief = {
    "THE LONG LEDGER",
    "",
    "Four corridors, each one longer than your patience for pressing l.",
    "The stairs between them are at alternating ends, which is not an accident.",
    "",
    "  0  ^  $        start / first ground / end of the line",
    "  f(  f\"  ;  ,   dash to a landmark character, then again, then back",
    "  gg  G  5G      top, bottom, an exact line",
    "",
    "The creatures here are the ones you already know - imps, trolls, words and",
    "grubs. What is new is reaching them without walking.",
    "",
    "Goal: work down through all four corridors to the portal ( > ) in the",
    "south-east. Nothing forces you to kill anything on the way.",
  },

  intro = "The Long Ledger. Nothing here is close to anything else.",
}
