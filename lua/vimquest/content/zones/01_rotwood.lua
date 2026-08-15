-- Zone 1 - The Rotwood
--
-- Teaches: operators are attacks. x, dw/de, di"/ci", di(/ca(, dd, 3dw, and the
-- dot-repeat combo. One roaming shambler keeps the clock running so the edits
-- happen under real pressure.
--
-- Authoring notes: the map is a 3x3 grid of rooms, 20 cells of interior each,
-- separated by walls with '+' doorways. Text-mobs are authored as a RUN of
-- their legend character exactly as long as the mob's body, so their footprint
-- is visible here and the loader rejects a mistyped row rather than shifting it.
-- Every row must be 64 characters. '#' is solid; '+' is a door and is walkable.

return {
  id = "01_rotwood",
  name = "The Rotwood",
  solid = "#",
  floor = ".",
  combat = true,

  map = {
    "################################################################",
    "#....................#....................#....................#",
    "#..THE.ROTWOOD.......#...THE.GRUB.NEST....#..THE.BLIGHT.WORDS..#",
    "#....@.....1.........+..2.....o......o....+..3....rrr....mmmm..#",
    "#....................#.......o............#.....bbbbbb.........#",
    "#....................#....................#....................#",
    "####################################################+###########",
    "#....................#....................#....................#",
    "#..THE.WRAITH.LINE...#..THE.TROLL.SPAN....#...THE.WHISPERERS...#",
    "#..6.................+..5...ttttttt.......+..4.....qqqqq.......#",
    "#....................#......ttttttt.......#.........qqqqq......#",
    "#wwwwwwwwwwwwwwwwwwww#....................#....................#",
    "##########+#####################################################",
    "#....................#....................#....................#",
    "#..THE.ROT.SWARM.....#...THE.ROTWOOD.PIT..#....THE.WAY.OUT.....#",
    "#..7.................+..8...o....rrr......+..9............>....#",
    "#...ssssssssssss.....#.....qqqqq....g.....#....................#",
    "#....................#....................#....................#",
    "################################################################",
  },

  legend = {
    ["@"] = { type = "spawn" },

    ---------------------------------------------------------------- text-mobs
    ["o"] = { type = "mob", mob = "grub" },
    ["r"] = { type = "mob", mob = "word_mob", text = "rot" },
    ["m"] = { type = "mob", mob = "word_mob", text = "mold", name = "mold-word" },
    ["b"] = { type = "mob", mob = "word_mob", text = "blight", name = "blight-word" },
    ["q"] = { type = "mob", mob = "quoted_imp" },
    ["t"] = { type = "mob", mob = "bracket_troll" },
    ["w"] = { type = "mob", mob = "line_wraith", text = "all of this is wrong" },
    ["s"] = { type = "mob", mob = "swarm" },

    ["g"] = {
      type = "entity",
      kind = "rot_shambler",
      name = "rot shambler",
      glyph = "g",
      behaviour = "chaser",
      speed = 11,
      hp = 3,
    },

    ------------------------------------------------------------------ signposts
    ["1"] = {
      type = "trigger",
      title = "The wood is made of words",
      text = {
        "Here the Buffer is soft. The text can be cut - and so can you.",
        "",
        "Everything coloured in this zone is alive. You kill it by performing the",
        "correct vim edit while standing on it. Nothing else works, and nothing",
        "else matters: any keystroke path that produces the right edit counts.",
        "",
        "A wrong edit is safe. The map repaints itself and you lose a little",
        "stamina - so experiment freely. You cannot break this world.",
        "",
        "Press <F3> at any time for the cheatsheet. It lists every command you",
        "have learned, and the world freezes while you read it.",
      },
    },

    ["2"] = {
      type = "trigger",
      title = "Grubs - x",
      text = {
        "Rot grubs ( o ) are single characters. One press kills one grub:",
        "",
        "    x    delete the character under the cursor",
        "",
        "Stand exactly on a grub and press x. Three of them nest in this room.",
        "",
        "Try x on the floor as well, and watch the Buffer knit itself shut.",
        "That is what a miss costs you: stamina, never damage.",
      },
    },

    ["3"] = {
      type = "trigger",
      title = "Blight-words - dw and de",
      text = {
        "Blight-words are whole words: rot, mold, blight.",
        "One character at a time will not do it. You need an operator and a motion:",
        "",
        "    dw   delete from the cursor to the start of the next word",
        "    de   delete to the end of this word",
        "    cw   delete the word and drop you into insert to replace it",
        "",
        "d is the operator. w and e are the motions you already know from walking.",
        "That is the whole grammar of vim: operator + motion. Everything else in",
        "this game is that idea again, aimed at something new.",
        "",
        "After the first kill, try . - the dot repeats your last strike exactly,",
        "and repeats build a combo that multiplies the experience you earn.",
      },
    },

    ["4"] = {
      type = "trigger",
      title = 'Quoted imps - di" and ci"',
      text = {
        'An imp hides inside quotes: "imp". The quotes are its cage.',
        "",
        '    di"   delete inside the quotes, leaving ""',
        '    ci"   the same, then start typing in its place',
        '    da"   delete the quotes as well',
        "",
        "i means inside. a means around - it takes the delimiters too.",
        "",
        "This is a text object, and it does not care where you stand: anywhere on",
        'the line before or inside the quotes, di" finds the pair for you. Text',
        "objects are the reason vim users stop counting characters.",
      },
    },

    ["5"] = {
      type = "trigger",
      title = "Bracket trolls - di( and ca(",
      text = {
        "A bracket troll wears its brackets: (troll).",
        "",
        "    di(   delete inside the brackets, leaving ()",
        "    ca(   delete the brackets and their contents, then type over them",
        "",
        "Unlike quotes, brackets do not search forward for you: you must be",
        "standing inside the pair. Walk into the troll's belly first, then strike.",
        "",
        "di) and dib do exactly the same thing - vim gives you three ways to say it.",
      },
    },

    ["6"] = {
      type = "trigger",
      title = "The line-wraith - dd",
      text = {
        "Below you an entire line has gone wrong. A line-wraith has taken it,",
        "and no word-sized strike will shift it.",
        "",
        "    dd    delete the whole line",
        "    D     delete from the cursor to the end of the line",
        "    d$    the same thing, spelled out",
        "",
        "Stand anywhere on the wraith's line and use dd. The wood grows back:",
        "walls, floor and all. The map is always the truth here.",
      },
    },

    ["7"] = {
      type = "trigger",
      title = "The swarm - counts",
      text = {
        "Three blight-words moving together: rot mold rip.",
        "Kill them one at a time and the rest close on you. Kill them at once:",
        "",
        "    3dw   one strike, three words",
        "",
        "A number in front of a command multiplies it. 3dw, 5j, 2ci( - the count",
        "goes first and the command does the rest. A single dw here is not enough,",
        "and the swarm will shrug it off.",
      },
    },

    ["8"] = {
      type = "trigger",
      title = "The pit - everything at once",
      text = {
        "No signpost tells you which is which now. Read the shape of the thing:",
        "",
        "    o          a grub          x",
        "    rot        a word          dw",
        '    "imp"      an imp          di"',
        "",
        "A rot shambler ( g ) hunts this room and it cannot be killed - not yet.",
        "Contact costs health, so keep moving and keep your strikes clean.",
        "",
        "The way out is east.",
      },
    },

    ["9"] = {
      type = "trigger",
      title = "The way out",
      text = {
        "The portal ( > ) stands at the end of this room.",
        "",
        "Nothing forces you through it. Unfinished mobs are still standing back",
        "there, and skills only level by use - grinding a weak one here makes",
        "everything after it easier.",
        "",
        "Step onto the portal when you are done. Your levels are saved.",
      },
    },

    [">"] = {
      type = "exit",
      leaves = ">",
      text = "The rot thins. You step through, and the wood closes behind you.",
    },
  },

  brief = {
    "THE ROTWOOD",
    "",
    "The Buffer is soft here. Text can be cut - which means text can be killed.",
    "",
    "Everything coloured in this zone is a creature made of characters, and each",
    "one dies to a particular vim command. The signposts teach them in order.",
    "",
    "  x                a single character      dw / de     a whole word",
    '  di" / ci"        inside the quotes       di( / ca(   inside the brackets',
    "  dd               a whole line            3dw         a count, three words",
    "  .                repeat the last strike, and build a combo",
    "",
    "A wrong edit never breaks anything. The map repaints and you lose a little",
    "stamina, so try things. The rot shambler in the pit still cannot be killed.",
    "",
    "  <F1> journal      <F2> pause      <F3> cheatsheet      <Esc><Esc> leave",
    "",
    "Goal: work east and south through the wood, and reach the portal ( > ).",
  },

  intro = "The Rotwood breathes. Here, the text bleeds.",
}
