-- Perks. Data only: a perk describes what it changes, and systems/perks.lua
-- knows how to apply each kind of change.
--
-- Effect vocabulary (all optional, all additive):
--   max_hp          extra health
--   stamina_regen   extra stamina per tick
--   stamina_cost    table of key -> new cost, merged over config
--   miss_stamina    change to what a wrong strike costs (negative is kinder)
--   combo_bonus     extra xp multiplier per combo step
--   xp_multiplier   extra multiplier on every kill
--
-- `requires` gates a perk behind skill levels; `cost` is in perk points, which
-- come from character levels and quest rewards.

return {
  {
    id = "sure_step",
    name = "Sure Step",
    cost = 1,
    desc = "hjkl costs 1 stamina instead of 2. Walking stops being a punishment.",
    effects = { stamina_cost = { h = 1, j = 1, k = 1, l = 1 } },
  },
  {
    id = "deep_lungs",
    name = "Deep Lungs",
    cost = 1,
    desc = "Stamina returns half again as fast.",
    effects = { stamina_regen = 0.25 },
  },
  {
    id = "thick_hide",
    name = "Thick Hide",
    cost = 1,
    desc = "+3 maximum health.",
    effects = { max_hp = 3 },
  },
  {
    id = "steady_hand",
    name = "Steady Hand",
    cost = 1,
    requires = { operator = 3 },
    desc = "A strike that goes wide costs 4 stamina instead of 8. Practise cheaply.",
    effects = { miss_stamina = -4 },
  },
  {
    id = "momentum",
    name = "Momentum",
    cost = 2,
    requires = { operator = 4 },
    desc = "Every step of a combo is worth more. Chain your kills with the dot.",
    effects = { combo_bonus = 0.15 },
  },
  {
    id = "quick_study",
    name = "Quick Study",
    cost = 2,
    requires = { textobject = 3 },
    desc = "Everything you kill teaches 25% more.",
    effects = { xp_multiplier = 0.25 },
  },
  {
    id = "wayfarer",
    name = "Wayfarer",
    cost = 2,
    requires = { motion = 4 },
    desc = "+4 maximum health and stamina regenerates faster still. The long roads open.",
    effects = { max_hp = 4, stamina_regen = 0.25 },
  },
}
