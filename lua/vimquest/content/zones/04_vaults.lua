-- Zone 4 - The Nested Vaults
--
-- Teaches: nesting. di( versus da(, and then the thing that makes text objects
-- powerful - a count reaches outward one pair at a time. The vault seals demand
-- 2di(, and the Nested Heart at the bottom demands 3ci(.
--
-- This is the first zone that asks the player to *compose*: a count, an object
-- and an operator in one breath. Nothing new is introduced to get here; it is
-- three known things said together, which is the point of a boss.
--
-- Authoring notes: every row is 64 characters.

return {
  id = "04_vaults",
  name = "The Nested Vaults",
  solid = "#",
  floor = ".",
  combat = true,

  map = {
    "################################################################",
    "#..............................................................#",
    "#..THE.NESTED.VAULTS...........................................#",
    "#....@.....1...................................................#",
    "#..........ttttttt...............ttttttt.......................#",
    "#..............................................................#",
    "################################.###############################",
    "#..............................................................#",
    "#..THE.SEALED.GALLERY..........................................#",
    "#....2........ssssssss..............ssssssss...................#",
    "#..................................................ssssssss....#",
    "#..............................................................#",
    "##########.#####################################################",
    "#..............................................................#",
    "#..THE.HEART.OF.THE.VAULT......................................#",
    "#....3.........................................................#",
    "#..............hhhhhhhhhhh.....................................#",
    "#..............................................................#",
    "#.........................>....................................#",
    "################################################################",
  },

  legend = {
    ["@"] = { type = "spawn" },
    ["t"] = { type = "mob", mob = "bracket_troll" },
    ["s"] = { type = "mob", mob = "vault_seal" },
    ["h"] = { type = "mob", mob = "vault_heart" },

    ["1"] = {
      type = "trigger",
      title = "Inside, or around",
      text = {
        "Two bracket trolls stand ahead: (troll).",
        "",
        "    di(   delete what is INSIDE the brackets, leaving ()",
        "    da(   delete the brackets AROUND it as well, leaving nothing",
        "    ci(   empty the inside and start typing there",
        "",
        "i and a are the whole vocabulary of text objects. Everything else -",
        'i" a" i( a( iw aw it at - is those two letters aimed somewhere new.',
        "",
        "Either one kills a troll. Below, the difference starts to matter.",
      },
    },

    ["2"] = {
      type = "trigger",
      title = "Nesting - a count reaches outward",
      text = {
        "A vault seal wears two pairs of brackets: ((seal))",
        "",
        "Stand on the word and press di( and you take the inner pair's contents -",
        "the seal barely notices. To take the pair OUTSIDE that one:",
        "",
        "    2di(   the second pair out from where you stand",
        "    2ci(   the same, and type over it",
        "    2da(   the second pair, brackets and all",
        "",
        "The count goes in front, exactly as it does for 3dw or 5j. That is the",
        "whole idea: counts, operators and objects are separate words, and you",
        "get to say them in any combination.",
        "",
        "Three seals here. Nothing but a count will open them.",
      },
    },

    ["3"] = {
      type = "trigger",
      title = "The Nested Heart",
      text = {
        "It has been here longer than the vault has.",
        "",
        "    (((heart)))",
        "",
        "Three pairs. Stand on the word, count outward, and say it in one breath:",
        "",
        "    3ci(   or   3di(   or   3da(",
        "",
        "Anything shallower glances off. This is the first thing in the Buffer",
        "that cannot be killed by a command you learned in isolation - only by",
        "putting three of them together.",
        "",
        "The portal ( > ) is below, and it leads home.",
      },
    },

    [">"] = {
      type = "exit",
      leaves = ">",
      to = "02_coldbuffer",
      text = "The vault exhales. The road back to Coldbuffer opens.",
    },
  },

  brief = {
    "THE NESTED VAULTS",
    "",
    "Everything down here is wrapped in something, and most of it is wrapped",
    "twice. This is where text objects stop being a trick.",
    "",
    "  di(  ca(       inside the brackets / around them",
    "  2di(  2ci(     reach past the inner pair to the one outside it",
    "  3ci(           three pairs deep - the Heart, at the bottom",
    "",
    "The counts are not decoration. A seal ignores di( entirely.",
    "",
    "Goal: open the gallery, put down the Nested Heart, take the portal home.",
  },

  intro = "The Nested Vaults. Something down here is still sealed.",
}
