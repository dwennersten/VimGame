# VimQuest build list

The working checklist. Tick items as they land; each segment ends with a commit and a
playable build. Vision and locked decisions live in [DESIGN.md](DESIGN.md); session
orientation in [CLAUDE.md](CLAUDE.md); feature rationale in
[suggested_features.md](suggested_features.md) (F-numbers below refer to it); authoring
rules in [CONTENT.md](CONTENT.md). **A full build spec for S3 is at the bottom of this
file.**

**Convention:** pick the next unchecked item in the lowest open segment. Anything marked
`[blocked]` needs a decision from Dan first.

---

## S1 — Engine core ✅ shipped

- [x] Repo scaffold, MIT, isolated launcher (`NVIM_APPNAME=vimquest`)
- [x] Grid/coords, tick loop, focus auto-pause (F3)
- [x] `CursorMoved` wall collision — the cursor is the player
- [x] Entity spawning + `chaser` / `pacer` behaviours
- [x] Keystroke recorder (F2), stamina economy (F8)
- [x] Winbar vitals + statusline messages
- [x] Declarative zone loader with in-map legend positioning (F18)
- [x] Zone 0 "The Awakening" (F5)
- [x] Headless smoke test (`tests/smoke.lua`)

## S1.1 — Readability patch ✅ shipped

- [x] Modal dialogue panels — world freezes while you read, dismiss with `<CR>`
- [x] Journal (`<F1>`) — re-read everything said this run, scrollable with j/k/gg/G
- [x] Opening briefing panel listing goal + controls before the zone starts
- [x] Exit portal `>` and a ZONE CLEARED summary (time, keys pressed, health)
- [x] Reusable floating `ui/panel.lua` (also the base for cheat panel + skill tree)

## S2 — Combat and progression ✅ shipped

- [x] Unlock the buffer during combat (`modifiable` toggling, undo-safe)
- [x] `engine/combat.lua`: resolve operator+motion against mobs
- [x] Mob schema in `content/mobs.lua`: word-mob (`dw`), quoted imp (`di"`),
      bracket troll (`ca(`), adjacent grub (`x`), line-wraith (`dd`), swarm (`3dw`)
- [x] Damage/kill feedback: flash highlight, XP popup, combo meter on `.`
- [x] `systems/skills.lua` — skill-by-use XP (Motion / Operator / Text-object / Count), levels
- [x] `save/` with `schema_version` + `migrate.lua` (F4), `:VimQuest reset`
- [x] `ui/cheatsheet.lua` — always-available reference of unlocked commands (`<F3>`)
- [x] Zone 1 "The Rotwood"
- [x] Smoke tests for combat resolution and save round-trip

## S3 — World loop  ← next

- [ ] Hub town "Coldbuffer" — safe zone, no tick damage
- [ ] Fast travel via marks (`ma` / `'a`) as shrines
- [ ] `systems/quests.lua` — quest state machine, `ui/questlog.lua`
- [ ] `systems/bounties.lua` — radiant 5–10 min contracts
- [ ] `ui/skilltree.lua` — perk points, ability unlocks
- [ ] `ui/dialogue.lua` NPCs with branching lines
- [ ] Zones 2–3 + first composition boss (`2ci(`-class combos) (F10)

## S4 — Learning intelligence

- [ ] `systems/score.lua` — par keystroke counts, 3-star grading (F6)
- [ ] `systems/replay.lua` — ghost playback of the optimal solution on death (F7)
- [ ] `systems/adaptive.lua` — per-command accuracy/speed tracking
- [ ] Weakness-seeking spawns + toggle
- [ ] SM-2-lite review scheduling surfaced as bounties (F9)
- [ ] Skill report dashboard

## S5 — Advanced curriculum

- [ ] Registers as inventory (`"ay`, `p`), marks as waypoints
- [ ] Macro zone — `q` record, `@a` replay as a summoned ultimate
- [ ] `:s` enchanting, `:g` mass-banishment mechanics
- [ ] Search `/` and `n`/`N` as scrying
- [ ] Config-quest guild with **runtime** validation (F16)
- [ ] Real-file endgame zones over copies of actual code (F13)
- [ ] LSP/quickfix zone — `gd`, `]d`, `:cnext` (F21)

## S6 — Distribution

- [ ] plenary test suite + GitHub Actions CI (F12)
- [ ] `:checkhealth vimquest` (F17)
- [ ] `doc/vimquest.txt` help file + tags
- [ ] Terminal capability detection, unicode/nerd-font fallbacks (F11)
- [ ] Daily seeded challenge with shareable score (F14)
- [ ] Achievements and titles (F15)
- [ ] Progress export: markdown skill report + personal cheatsheet (F22)
- [ ] Public GitHub repo — **confirm repo name and account before pushing**

## Backlog / post-S6

- [ ] Async ghost racing against a friend's seed (F19)
- [ ] Telescope integration as in-world scrying (F20)
- [ ] Sound-free "juice" pass: screen shake via winbar, damage flashes, death animation
- [ ] Difficulty presets (relaxed / standard / brutal)

---

## What S2 delivered (read this before extending combat)

Killing something means editing it correctly. The engine watches the **buffer**, not the
keystrokes, so any keystroke path that produces the right edit counts — that is what
fluency looks like, and it is why `dw`, `2dw` from a different cell, or `cw` + `<Esc>` all
work. The keylog is consulted only to decide *which* command earned the credit.

Three rules hold the whole thing up:

1. **`zone.map` is the truth, the buffer is a view.** `combat.compose()` renders terrain
   plus living mobs; `combat.paint()` writes it back after every change. Nothing the player
   types can corrupt the world, so a wrong edit costs only stamina.
2. **Strikes are judged by byte region, not by content.** `on_bytes` gives the columns the
   edit touched; a mob is attacked only if that region overlaps its body. Content diffing
   fails here — deleting one grub shifts the rest of the line left.
3. **Only typed keys are player input.** `vim.on_key` also reports Neovim's internal
   expansion (pressing `x` really feeds `x`, `d`, `l`). `engine/input.lua` filters those.

Weaknesses are Lua patterns matched against the *tail* of the keys pressed since the last
change, so approach motions in front of a strike are ignored. `.` is rewritten to the
command it repeats before matching.

---

## S3 build spec — start here

Goal: **a world, not a corridor.** After S3 the player has somewhere to return to, reasons
to go back out, and a choice about what to train next. This is the segment that turns two
zones into the Skyrim-shaped loop Dan asked for.

### The shape of it

Coldbuffer is the hub: no tick damage, no mobs, NPCs standing on the map who talk when you
step on them. From there the player takes a quest or a bounty, walks to a zone, and comes
back with levels. Fast travel is `'a` to a shrine you marked with `ma` — the mechanic is
literally the vim feature it teaches.

### Checklist

- [ ] Hub zone `02_coldbuffer`: `safe = true` on the zone, honoured by `engine/tick.lua`
      (no contact damage, no exhaustion bleed) — a new zone flag, not a special case
- [ ] `systems/quests.lua`: quest state machine (offered → active → complete), objectives
      expressed as data (`kill n of kind`, `reach zone`, `clear zone`), persisted in `save/`
- [ ] `ui/questlog.lua` on `<F4>`, built on `ui/panel.lua`
- [ ] `ui/dialogue.lua` NPC branching: legend `type = "npc"` with a line tree, choices
      picked with `j`/`k`/`<CR>` — panels already freeze the world
- [ ] `systems/bounties.lua`: radiant 5–10 minute contracts generated from the mob roster
      ("clear 5 bracket trolls with `ca(`"), the 10-minute session shape from DESIGN.md
- [ ] Marks as shrines: a legend `type = "shrine"`; `ma` there registers fast travel, `'a`
      returns. Teaches marks by making them the only convenient travel
- [ ] `ui/skilltree.lua`: perk points from character levels, perks as data in
      `content/perks.lua`, at least one that gates a zone
- [ ] Zone 2 "The Long Ledger": `0 ^ $`, `f t ; ,`, `gg G`, `{ }` under pressure
- [ ] Zone 3 "The Nested Vaults": nested text objects, `di(` vs `da(`
- [ ] First composition boss: a `2ci(`-class mob — needs `weakness` patterns with counts
      *and* text objects, which the current matcher already supports (F10)
- [ ] Smoke tests: quest state transitions, bounty generation, save round-trip at
      `schema_version = 2` (add the migration from 1 in the same commit)

### Watch out for

- **`safe = true` must be a zone flag the engine reads**, not an `if zone.id == ...`.
  Content is data; if the hub needs a capability the engine lacks, add the named flag.
- **Bumping `schema_version` requires a migration from 1.** `save/migrate.lua` has the
  shape ready; a save that loses a player's levels is a bug, never an acceptable cost.
- Zone 2's `f{char}` lessons need landmark characters in the map that are *not* legend
  characters — the loader paints legend chars over with floor.

### Acceptance

Start in Coldbuffer, take a bounty from an NPC, mark a shrine with `ma`, clear the bounty
in the Rotwood, `'a` back, hand it in, and spend a perk point — with levels, quest state
and perks all surviving a relaunch.

---

## Known rough edges

- [ ] Zone maps are hand-drawn; width and mob-run validation should run in CI (currently
      only checked by `tests/smoke.lua`, which does cover both zones)
- [ ] Maps are ASCII-only by design (byte columns must equal screen cells). Unicode tiles
      need a width-aware renderer before they can be used.
- [ ] `pacer` behaviour is implemented but still unused; Zone 2 is the natural place for it.
- [ ] `u` does nothing in combat: the game buffer sets `undolevels = -1`, which is what
      keeps stray edits from stacking an undo history. The "time-rewind potion" in
      DESIGN.md needs a real decision about undo before it can exist.
- [ ] A `c`-operator kill force-exits insert mode via `feedkeys`. It works, but if S3 adds
      a mob that is killed *by typing a replacement*, that behaviour has to become
      conditional on the mob.
