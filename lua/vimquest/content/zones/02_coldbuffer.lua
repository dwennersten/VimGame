-- Zone 2 - Coldbuffer (the hub)
--
-- A safe zone: `safe = true` tells engine/tick.lua to stop dealing contact and
-- exhaustion damage, so this is somewhere to stand and think. No mobs, no
-- clock. People, a bounty board, a shrine, and doors to everywhere else.
--
-- Authoring notes: every row is 64 characters. Legend keys are lowercase and
-- digits; the map's labels are uppercase, so they can never collide. NPCs
-- `leaves` an uppercase initial so you can tell who is who from across town.

return {
  id = "02_coldbuffer",
  name = "Coldbuffer",
  solid = "#",
  floor = ".",
  safe = true,
  combat = false,

  map = {
    "################################################################",
    "#..............................................................#",
    "#...COLDBUFFER...THE.LAST.QUIET.PLACE.IN.THE.BUFFER............#",
    "#..............................................................#",
    "#....##########.......##########.......##########..............#",
    "#....#........#.......#........#.......#........#..............#",
    "#....#...w....+.......#...a....+.......#...t....+......^.......#",
    "#....#........#.......#........#.......#........#..............#",
    "#....##########.......##########.......##########..............#",
    "#.....WARDEN...........ARCHIVIST.........TRAINER.....SHRINE....#",
    "#..............................................................#",
    "#.......@.......1...............2..............3...............#",
    "#..............................................................#",
    "#....############..............................................#",
    "#....#...b......+.....THE.BOUNTY.BOARD.........................#",
    "#....############..............................................#",
    "#..............................................................#",
    "#.....ROTWOOD..........LEDGER...........VAULTS.................#",
    "#.......r...............l................v.....................#",
    "################################################################",
  },

  legend = {
    ["@"] = { type = "spawn" },

    ["^"] = {
      type = "shrine",
      leaves = "^",
      name = "the Coldbuffer shrine",
    },

    ------------------------------------------------------------------- doors
    ["r"] = {
      type = "exit",
      leaves = ">",
      travel = true,
      to = "01_rotwood",
      text = "The road east, into the rot.",
    },
    ["l"] = {
      type = "exit",
      leaves = ">",
      travel = true,
      to = "03_ledger",
      text = "The road south, along the ledger.",
    },
    ["v"] = {
      type = "exit",
      leaves = ">",
      travel = true,
      to = "04_vaults",
      text = "The road down, into the vaults.",
    },

    -------------------------------------------------------------------- people
    ["w"] = {
      type = "npc",
      leaves = "W",
      id = "warden",
      name = "the Warden",
      dialogue = {
        start = {
          text = {
            "The Warden does not look up from the map she is redrawing.",
            "",
            '"You are the one who walked out of the Rotwood. Good. Most do not."',
          },
          choices = {
            { label = "What happened here?", to = "lore" },
            {
              label = "I want work.",
              to = "quest",
              action = { offer = "cut_back_the_rot" },
            },
            {
              label = "The wood is thinner now.",
              to = "reward",
              action = { turn_in = "cut_back_the_rot" },
            },
            { label = "Nothing for now." },
          },
        },
        lore = {
          text = {
            '"The Buffer was written once, cleanly. Then something started editing."',
            "",
            '"Now the text fights back. You have seen it - words that bite, lines that',
            'will not hold still. Coldbuffer is what is left that still parses."',
            "",
            '"We hold it by cutting. That is all any of us do here."',
          },
          choices = {
            { label = "And me?", to = "start" },
            { label = "I understand." },
          },
        },
        quest = {
          text = {
            '"Then go back and thin it. Blight-words and grubs - dw and x, nothing',
            'clever. Walk the wood end to end and come back to me."',
            "",
            "The quest is in your log. <F4> opens it.",
          },
          choices = {
            { label = "It will be done." },
          },
        },
        reward = {
          text = {
            '"You smell of rot and you are still standing."',
            "",
            '"Spend that point. The Trainer will show you how - the building with',
            'the T on the door."',
          },
          choices = {
            { label = "Thank you." },
          },
        },
      },
    },

    ["a"] = {
      type = "npc",
      leaves = "A",
      id = "archivist",
      name = "the Archivist",
      dialogue = {
        start = {
          text = {
            "The Archivist has one finger inside a book, holding a place.",
            "",
            '"Everything is wrapped in something," he says, without preamble.',
          },
          choices = {
            { label = "Wrapped in what?", to = "lore" },
            {
              label = "Show me.",
              to = "quest",
              action = { offer = "cages_and_brackets" },
            },
            {
              label = "Two imps and two trolls, as asked.",
              to = "reward",
              action = { turn_in = "cages_and_brackets" },
            },
            { label = "Later." },
          },
        },
        lore = {
          text = {
            '"Quotes. Brackets. Tags. The wrapper is never the thing."',
            "",
            '"A novice deletes character by character until the shape looks right.',
            'An archivist says i - inside - and the shape is simply gone."',
            "",
            '  di"   inside the quotes        da"   the quotes as well',
            "  di(   inside the brackets      ca(   the brackets, and type over them",
            "",
            '"It does not matter where you stand inside the pair. That is the point."',
          },
          choices = {
            { label = "Give me something to practise on.", to = "start" },
            { label = "I will remember." },
          },
        },
        quest = {
          text = {
            '"Two imps, emptied from inside. Two trolls, however you like."',
            "",
            '"The imps matter. Reach *inside* the quotes - di" or ci". If you take',
            'the cage along with the imp I will know, and it will not count."',
          },
          choices = {
            { label = "Inside. Understood." },
          },
        },
        reward = {
          text = {
            '"Inside, not around. You see it now."',
            "",
            '"That distinction is worth more than the levels it just paid you."',
          },
          choices = {
            { label = "It is." },
          },
        },
      },
    },

    ["t"] = {
      type = "npc",
      leaves = "T",
      id = "trainer",
      name = "the Trainer",
      dialogue = {
        start = {
          text = {
            "The Trainer is sharpening nothing in particular.",
            "",
            '"You do not get better here. You get better out there. I just make sure',
            'it sticks."',
          },
          choices = {
            { label = "Spend my perk points.", action = { perks = true } },
            { label = "How do I get stronger?", to = "lore" },
            { label = "Patch me up.", action = { heal = true } },
            { label = "Nothing today." },
          },
        },
        lore = {
          text = {
            '"Four skills, and each one levels from doing the thing itself."',
            "",
            "  Motion       w b e, counts, blinks",
            "  Operator     x d c and what they reach",
            "  Text-object  the i and a business - ask the Archivist",
            "  Count        a number in front of a command",
            "",
            '"Every second level is a perk point. Grinding a weak skill is never',
            'wasted time - it is the only kind of time that is not."',
          },
          choices = {
            { label = "Spend my perk points.", action = { perks = true } },
            { label = "Good." },
          },
        },
      },
    },

    ["b"] = {
      type = "npc",
      leaves = "B",
      id = "board_keeper",
      name = "the Board-keeper",
      dialogue = {
        start = {
          text = {
            "A woman sits under a wall of nailed-up paper, reading none of it.",
            "",
            '"Contracts," she says. "Short ones. Take what you like."',
          },
          choices = {
            { label = "Show me the board.", action = { board = true } },
            { label = "How does this work?", to = "lore" },
            { label = "Not now." },
          },
        },
        lore = {
          text = {
            '"A bounty is one job: clear so many of a thing, come back, get paid."',
            "",
            '"They pay into whatever skill they drill, so if something in your hands',
            'feels slow, take the bounty for it. Ten minutes and it feels less slow."',
            "",
            '"The board changes daily. It never runs out."',
          },
          choices = {
            { label = "Show me the board.", action = { board = true } },
            { label = "Understood." },
          },
        },
      },
    },

    ----------------------------------------------------------------- signposts
    ["1"] = {
      type = "trigger",
      title = "Coldbuffer",
      text = {
        "Nothing here can hurt you. No clock, no contact damage, no exhaustion.",
        "",
        "This is where you come back to. Four people are worth talking to:",
        "",
        "  W   the Warden        work in the Rotwood",
        "  A   the Archivist     text objects, and a quest about them",
        "  T   the Trainer       spend perk points, and get patched up",
        "  B   the Board-keeper  short bounties, always available",
        "",
        "Walk into someone to talk. Choose a reply with j / k and <CR>.",
      },
    },

    ["2"] = {
      type = "trigger",
      title = "The shrine - marks and fast travel",
      text = {
        "The shrine ( ^ ) to the north-east is a waypoint, and binding it is a",
        "real vim command:",
        "",
        "    ma    stand on the shrine and press m then a - the shrine is now 'a",
        "    'a    from anywhere, in any zone, return to it",
        "",
        "Any letter a-z works, so you can bind several places. In your editor the",
        "same keys mark a spot in a file and jump back to it, which is the entire",
        "point of this game: the shrine is not a metaphor for marks. It IS marks.",
        "",
        "Bind this one before you leave town. You will want the way back.",
      },
    },

    ["3"] = {
      type = "trigger",
      title = "The roads out",
      text = {
        "Three portals ( > ) stand along the south wall:",
        "",
        "  ROTWOOD   operators and text objects - where you came from",
        "  LEDGER    line anchors and character search, under pressure",
        "  VAULTS    nested text objects, and something old at the bottom",
        "",
        "Walking into a portal takes you straight there - no summary, no ending",
        "the run. Come back the same way, or with a shrine mark.",
        "",
        "  <F3> cheatsheet     <F4> quest log     <F5> skill tree",
      },
    },
  },

  brief = {
    "COLDBUFFER",
    "",
    "The last quiet place in the Buffer. Nothing here can hurt you: no clock,",
    "no contact damage, no exhaustion. Stand as long as you like.",
    "",
    "  Walk into someone to talk       j / k choose a reply, <CR> to say it",
    "  ma on the shrine ( ^ )          binds it; 'a returns from anywhere",
    "  Walk into a portal ( > )        travel, with no summary screen",
    "",
    "  <F3> cheatsheet    <F4> quest log    <F5> skill tree    <F1> journal",
    "",
    "Goal: take work from the Warden or the board, and come back richer.",
  },

  intro = "Coldbuffer. The text here still parses.",
}
