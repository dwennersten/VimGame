# VimQuest build list

The working checklist. Tick items as they land; each segment ends with a commit and a
playable build. Vision and locked decisions live in [DESIGN.md](DESIGN.md); session
orientation in [CLAUDE.md](CLAUDE.md); feature rationale in
[suggested_features.md](suggested_features.md) (F-numbers below refer to it); authoring
rules in [CONTENT.md](CONTENT.md). **A full build spec for S4 is at the bottom of this
file**, under short summaries of what S2 and S3 delivered.

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

## S3 — World loop ✅ shipped

- [x] Hub town "Coldbuffer" — safe zone, no tick damage (`safe = true` zone flag)
- [x] Fast travel via marks (`ma` / `'a`) as shrines
- [x] `systems/quests.lua` — quest state machine, `ui/questlog.lua` (`<F4>`)
- [x] `systems/bounties.lua` — radiant 5–10 min contracts, `ui/board.lua`
- [x] `ui/skilltree.lua` — perk points, ability unlocks (`<F5>`)
- [x] `ui/converse.lua` NPCs with branching lines, gated on quest state
- [x] Zones 2–3 + first composition boss (`3ci(` — the Nested Heart) (F10)

## S4 — Learning intelligence  ← next

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

## What S3 delivered (read this before adding systems)

The world loop: Coldbuffer (hub) → quest or bounty → a zone → back with levels. The map is
`00_awakening → 01_rotwood → 02_coldbuffer ⇄ {03_ledger, 04_vaults}`.

Patterns worth reusing rather than reinventing:

- **New engine capabilities arrive as named zone flags**, never as a check on a zone id.
  `safe = true` is the model: `engine/tick.lua` reads it and stops dealing damage, so any
  future sanctuary gets the behaviour for free.
- **Systems never know about specific content.** The engine reports events
  (`quests.on_kill`, `on_zone_cleared`, `on_zone_entered`) and `systems/quests.lua` walks
  active quests looking for a match. Adding an objective kind is one branch in `advance`
  and one line in `describe`.
- **Perks declare what changes; one module knows how.** `systems/perks.lua` recomputes
  every effect from the owned set, so buying is order-independent and rebalancing a perk
  never needs a save migration.
- **`ui/menu.lua` is the one selectable panel.** Conversations, the bounty board and the
  skill tree are all the same component with different data. Anything that needs a list
  should use it.
- **A radiant quest carries its own definition** on the quest record, which is how a bounty
  survives a save without being written into `content/quests.lua`.

### S4 build spec — start here

Goal: **the game notices what you are bad at.** Everything needed is already recorded —
`state.keylog` has every typed key with a timestamp, and combat knows which command earned
each kill — so this segment is analysis, not new plumbing.

- [ ] `systems/score.lua`: par keystroke counts per zone, 3-star grading on the zone-clear
      panel (F6). Par is data on the zone, not a constant in the system.
- [ ] `systems/replay.lua`: ghost playback of the optimal solution on death (F7). The
      keylog format was designed for this; it needs a way to author the optimal line.
- [ ] `systems/adaptive.lua`: per-command accuracy and speed from the keylog. A miss
      already knows which mob shrugged and what was pressed — record it.
- [ ] Weakness-seeking spawns, with a toggle. Zones declare *what* can spawn; the system
      picks. Do not let this reach into zone files.
- [ ] SM-2-lite review scheduling surfaced as bounties (F9). `systems/bounties.lua` already
      isolates its choice of mob in `pick` — that is the hook.
- [ ] Skill report dashboard, built on `ui/panel.lua`.
- [ ] Smoke tests: par grading, accuracy tracking across a miss and a kill, and a save
      round-trip at `schema_version = 3` (with its migration from 2, in the same commit).

### Watch out for

- **`vim.on_key` only sees typed keys now.** That is correct for scoring, but it means a
  keystroke-golf par must be counted in typed keys too, not in Neovim's internal expansion.
- **Bumping `schema_version` requires the migration in the same commit.** Non-negotiable.
- Adaptive spawning must not make a zone unwinnable for a beginner; the toggle from
  DESIGN.md section 2 is a locked decision, not an optional extra.

### Acceptance

Clear a zone and get a keystroke-golf grade; fumble a command repeatedly and watch a
bounty for it appear on the board; open the skill report and see which commands are slow.

---

## Known rough edges

- [ ] Zone maps are hand-drawn; width and mob-run validation should run in CI (currently
      only checked by `tests/smoke.lua`, which does cover both zones)
- [ ] Maps are ASCII-only by design (byte columns must equal screen cells). Unicode tiles
      need a width-aware renderer before they can be used.
- [ ] **The Long Ledger is 76 columns wide** and nothing checks the terminal. On a narrower
      window it side-scrolls (`wrap=false`, `sidescrolloff=0`), which is playable but makes
      `$` land off-screen. Either cap zone width at ~64 or teach the renderer to report a
      too-small terminal — the capability detection in S6 (F11) is the natural home.
- [ ] `pacer` behaviour is implemented but still unused. The Ledger and the Vaults have no
      roaming creatures at all, so both are currently puzzle zones with no clock — the
      first thing to try if either feels flat.
- [ ] `{` and `}` are advertised nowhere any more: maps have no blank lines, so paragraph
      motions just reach the top and bottom of the map. Teaching them honestly needs a zone
      whose rows can be genuinely empty, which the uniform-width rule forbids today.
- [ ] `travel.attach` binds `m`, `'` and `` ` `` with `getcharstr()`, which blocks the world
      until the second key arrives. Fine for a two-key command, but do not extend the
      pattern to anything the player might abandon halfway.
- [ ] No perk gates a zone yet, though the S3 spec asked for one. Every zone is reachable
      from Coldbuffer from the start — deliberate for now, since gating hurts the
      ten-minute session, but revisit if the Vaults turn out to be too much too early.
- [ ] `u` does nothing in combat: the game buffer sets `undolevels = -1`, which is what
      keeps stray edits from stacking an undo history. The "time-rewind potion" in
      DESIGN.md needs a real decision about undo before it can exist.
- [ ] A `c`-operator kill force-exits insert mode via `feedkeys`. It works, but if S3 adds
      a mob that is killed *by typing a replacement*, that behaviour has to become
      conditional on the mob.
