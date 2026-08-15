-- Hand-written quests. Radiant contracts are generated in systems/bounties.lua
-- from this same shape.
--
-- Objective kinds and reward fields are documented in systems/quests.lua.
-- Quests are offered and handed in by NPCs; see the `npc` legend type in
-- CONTENT.md for how a conversation points at one.

return {
  cut_back_the_rot = {
    id = "cut_back_the_rot",
    name = "Cut Back the Rot",
    summary = "The Rotwood is spreading. The warden wants it thinned.",
    objectives = {
      { kind = "kill", mob = "word_mob", count = 4, text = "slay 4 blight-words (dw / de)" },
      { kind = "kill", mob = "grub", count = 3, text = "stamp out 3 rot grubs (x)" },
      { kind = "clear_zone", zone = "01_rotwood", text = "reach the Rotwood's portal" },
    },
    reward = { skills = { operator = 25, motion = 15 }, perk_points = 1 },
    on_offer = {
      "The wood was a road once. Now it is a mouth.",
      "",
      "Blight-words and grubs, that is all it is - and neither survives a clean",
      "cut. Thin them out and walk the wood end to end, then come back to me.",
    },
    on_complete = {
      "You smell of rot and you are still standing. Good.",
      "",
      "Take this. You have earned the right to spend it.",
    },
  },

  cages_and_brackets = {
    id = "cages_and_brackets",
    name = "Cages and Brackets",
    summary = "The archivist wants the delimiters emptied, not broken.",
    objectives = {
      { kind = "kill_with", mob = "quoted_imp", command = 'i"', count = 2, text = 'empty 2 imp cages (di" / ci")' },
      { kind = "kill", mob = "bracket_troll", count = 2, text = "put down 2 bracket trolls (di( / ca()" },
    },
    reward = { skills = { textobject = 40 }, perk_points = 1 },
    on_offer = {
      "Everything in this world is wrapped in something. Quotes, brackets,",
      "tags - the wrapper is never the thing.",
      "",
      "Learn to reach past the wrapper and you stop counting characters forever.",
      'i is inside. a is around. di" takes the imp; da" takes the cage as well.',
      "",
      "Bring me two imps and two trolls, and reach *inside* for the imps.",
    },
    on_complete = {
      "Inside, not around. You see it now.",
      "",
      "That distinction is worth more than the levels it just paid you.",
    },
  },
}
