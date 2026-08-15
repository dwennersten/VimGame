# Authoring content

The engine never needs editing to add content. A zone is one data file in
`lua/vimquest/content/zones/`, loaded by `lua/vimquest/content/zones/init.lua`.

## Zone file

```lua
return {
  id    = "01_rotwood",
  name  = "The Rotwood",
  solid = "#",          -- every character in this string blocks movement
  floor = ".",          -- what legend characters are replaced with
  intro = "Something rots here.",

  map = {               -- ASCII only, every row the same length
    "##########",
    "#..@....g#",
    "##########",
  },

  legend = {            -- characters extracted from the map at load time
    ["@"] = { type = "spawn" },
    ["1"] = { type = "trigger", text = "Shown when the player steps here." },
    [">"] = { type = "exit", leaves = ">", to = "02_next", text = "..." },
    ["r"] = { type = "mob", mob = "word_mob", text = "rot" },
    ["g"] = {
      type      = "entity",
      kind      = "rot_shambler",
      name      = "rot shambler",
      glyph     = "g",
      behaviour = "chaser",   -- see engine/entity.lua
      speed     = 9,          -- moves once every N ticks (tick = 100ms)
      hp        = 3,
    },
  },
}
```

**Rules**

- ASCII only. Byte columns must equal screen cells or collision and overlays desync.
- All rows must be the same length.
- Positions are authored *in the map*, never as numbers — no counting columns.
- A legend entry may set `leaves = "x"` to leave a different character behind.
- An `exit` may set `to = "<zone id>"`; the ZONE CLEARED panel then offers `n` to continue.
  Adding `travel = true` makes it a doorway instead: no summary, you just walk through.

**Zone flags**

| Flag | Effect |
| --- | --- |
| `combat = true` | unlocks the buffer and runs `engine/combat.lua`. Defaults to true if the zone has any text-mobs. |
| `safe = true` | no contact damage, no exhaustion bleed. The hub uses this. |

A new engine capability should arrive as a flag like these, read by the engine, never as a
check on a zone id.

**Legend types**

| `type` | Makes | Key fields |
| --- | --- | --- |
| `spawn` | where the player starts | — |
| `trigger` | a signpost that fires once when stepped on | `title`, `text`, `quiet` |
| `exit` | a portal | `to`, `travel`, `text` |
| `entity` | a roaming glyph drawn over the map | `kind`, `glyph`, `behaviour`, `speed`, `hp` |
| `mob` | a text-mob, killed by editing it | `mob` (roster key), `text` |
| `npc` | someone who talks when you walk into them | `id`, `name`, `dialogue` |
| `shrine` | a fast-travel waypoint, bound with `ma` | `name` |

Register the id in the `:VimQuest` completion list in `plugin/vimquest.lua`, and add it to
the zone list in `tests/smoke.lua` so its map is width-checked.

## Text-mobs

Two different things are called mobs, and they behave differently:

| | `type = "entity"` | `type = "mob"` |
| --- | --- | --- |
| What it is | a glyph drawn *over* the map as an extmark | real buffer text |
| Moves | yes, via `behaviour` | no |
| Killed by | nothing yet | performing its vim command on it |
| Purpose | the clock — pressure while you think | the puzzle — the lesson itself |

A text-mob is authored as a **run of its legend character exactly as long as its body**:

```lua
map = {
  "#..rrr....qqqqq..#",       -- 3 chars of 'rot', 5 chars of '"imp"'
},
legend = {
  ["r"] = { type = "mob", mob = "word_mob", text = "rot" },
  ["q"] = { type = "mob", mob = "quoted_imp" },     -- body comes from the roster
},
```

The footprint is visible in the map, and a run of the wrong length is a load-time error
rather than a silently shifted row. Any roster field can be overridden per instance
(`text`, `name`, `weakness`, `teaches`, `xp`, `hl`).

The roster lives in `lua/vimquest/content/mobs.lua`:

| Key | Body | Killed by | Teaches |
| --- | --- | --- | --- |
| `grub` | `o` | `x` | Operator |
| `word_mob` | `rot` | `dw` `de` `cw` | Operator + Motion |
| `quoted_imp` | `"imp"` | `di"` `ci"` `da"` | Text-object |
| `bracket_troll` | `(troll)` | `di(` `ca(` | Text-object |
| `line_wraith` | a whole line | `dd` `D` `d$` | Operator |
| `swarm` | `rot mold rip` | `3dw` | Count + Operator + Motion |

`weakness` is a list of **Lua patterns matched against the tail** of the keys pressed since
the last buffer change, so approach motions in front of a strike are ignored: `"d[we]"`
matches `lllldw`. Escape pattern metacharacters — `d%$`, `[dc][ia]%(`. `.` is rewritten to
the command it repeats before matching, which is what makes the combo meter work.

`teaches` maps skill key → xp; the keys come from `systems/skills.lua`. A mob that teaches
nothing is a bug, and the smoke test fails on it.

**A wrong strike is never destructive.** `engine/combat.lua` repaints the buffer from
`zone.map` after every change, so terrain damage and wrong operators cost stamina and
nothing else. Adding a mob cannot break the map.

## NPCs and conversations

An NPC is a legend entry with a `dialogue` table of nodes. Nodes and choices are data —
writing a character never means writing code.

```lua
["w"] = {
  type = "npc",
  leaves = "W",                       -- what stands on the map
  id = "warden",
  name = "the Warden",
  dialogue = {
    start = {
      text = { "She does not look up." },
      choices = {
        { label = "What happened here?", to = "lore" },
        { label = "I want work.", to = "given", action = { offer = "cut_back_the_rot" } },
        { label = "It is done.",  to = "paid",  action = { turn_in = "cut_back_the_rot" } },
        { label = "Nothing." },                       -- no `to` ends the talk
      },
    },
    lore = { text = { "..." }, choices = { { label = "I see." } } },
  },
},
```

**Actions** (`action = { ... }`): `offer = "<quest id>"`, `turn_in = "<quest id>"`,
`board = true` (bounty board), `perks = true` (skill tree), `heal = true`.

**Conditions**, checked before a choice is shown: `requires_quest`, `requires_done`,
`hidden_if_done`. An `offer` hides itself once taken; a `turn_in` only appears when every
objective is met. That covers most of what a quest-giver needs without any flags.

## Quests

`content/quests.lua` holds the hand-written ones; `systems/bounties.lua` generates radiant
ones with the same shape. Objectives are declarative:

```lua
objectives = {
  { kind = "kill",       mob = "word_mob", count = 4, text = "slay 4 blight-words" },
  { kind = "kill_with",  mob = "quoted_imp", command = 'i"', count = 2 },
  { kind = "clear_zone", zone = "01_rotwood" },
  { kind = "reach",      zone = "03_ledger" },
},
reward = { skills = { operator = 25 }, perk_points = 1 },
```

`kill_with` matches its `command` against the keys that landed the kill, which is how "use
`di"`, not `da"`" becomes an enforceable objective.

## Perks

`content/perks.lua` declares effects; `systems/perks.lua` applies them. The vocabulary is
`max_hp`, `stamina_regen`, `stamina_cost`, `miss_stamina`, `combo_bonus`, `xp_multiplier`.
A perk that needs something outside that list needs a new named effect in `systems/`, not
a function in the content file.

## Behaviours

Defined in `lua/vimquest/engine/entity.lua` as `M.behaviours.<name>(entity, ctx)` where
`ctx = { zone, prow, pcol }`. Current set: `idle`, `chaser`, `pacer`. Add a function there
to make a new one available to every zone.

## Coordinate convention

Engine-wide: `row` and `col` are **0-indexed**, matching the `nvim_buf_*` API. Cursor APIs
are 1-indexed for rows, so conversion happens only in `engine/grid.lua`.

## Module map

| Path | Responsibility |
| --- | --- |
| `config.lua` | all tunables (tick rate, damage, stamina costs, combat, saving) |
| `state.lua` | runtime singleton, `reset()`, `say()` |
| `engine/grid.lua` | coordinates, walkability, cursor conversion |
| `engine/render.lua` | tabpage/buffer lifecycle, highlights, entity + mob painting |
| `engine/collision.lua` | `CursorMoved` wall guard |
| `engine/input.lua` | keystroke recorder (typed keys only) + stamina charging |
| `engine/entity.lua` | spawning and behaviours for roaming creatures |
| `engine/combat.lua` | buffer watcher, kill/miss resolution, authoritative repaint |
| `engine/tick.lua` | world clock, damage, triggers |
| `systems/skills.lua` | skill-by-use xp, levels, character level, skill report |
| `systems/quests.lua` | objective state machine; the engine only reports events |
| `systems/bounties.lua` | radiant contracts generated from the mob roster |
| `systems/perks.lua` | turns declared perk effects into live tunables |
| `systems/travel.lua` | shrines, marks (`ma`), fast travel (`'a`) |
| `save/init.lua` | read/write progression under `stdpath("data")/vimquest/` |
| `save/migrate.lua` | `SCHEMA_VERSION` and forward migrations |
| `ui/hud.lua` | winbar vitals, foes remaining, combo meter, unspent perks |
| `ui/panel.lua` | the one floating panel; every UI builds on it |
| `ui/menu.lua` | the one selectable panel; conversations, board, skill tree |
| `ui/cheatsheet.lua` | `<F3>` command reference, unlocked by use |
| `ui/questlog.lua` | `<F4>` objectives |
| `ui/skilltree.lua` | `<F5>` perks |
| `ui/converse.lua` | NPC dialogue trees |
| `ui/board.lua` | the bounty board |
| `content/mobs.lua` | text-mob roster |
| `content/commands.lua` | what the cheatsheet lists |
| `content/quests.lua` | hand-written quests |
| `content/perks.lua` | the skill tree |
| `content/zones/` | zone data files |

When you add a zone, add its id to `ALL_ZONES` in `tests/smoke.lua`. That list drives the
structural checks: uniform row widths, a walkable spawn, exits you can stand on that point
at zones which exist, reachable NPCs and shrines, and no mob embedded in a wall.
