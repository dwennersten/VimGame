# VimQuest build list

The working checklist. Tick items as they land; each segment ends with a commit and a
playable build. Vision and locked decisions live in [DESIGN.md](DESIGN.md); session
orientation in [CLAUDE.md](CLAUDE.md); feature rationale in
[suggested_features.md](suggested_features.md) (F-numbers below refer to it); authoring
rules in [CONTENT.md](CONTENT.md). **A full build spec for S2 is at the bottom of this
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

## S2 — Combat and progression  ← next

- [ ] Unlock the buffer during combat (`modifiable` toggling, undo-safe)
- [ ] `engine/combat.lua`: resolve operator+motion against mobs
- [ ] Mob schema in `content/mobs.lua`: word-mob (`dw`), quoted imp (`di"`),
      bracket troll (`ca(`), adjacent grub (`x`)
- [ ] Damage/kill feedback: flash highlight, XP popup, combo meter on `.`
- [ ] `systems/skills.lua` — skill-by-use XP (Motion / Operator / Text-object), levels
- [ ] `save/` with `schema_version` + `migrate.lua` (F4), `:VimQuest reset`
- [ ] `ui/cheatsheet.lua` — always-available reference of unlocked commands
- [ ] Zone 1 "The Rotwood"
- [ ] Smoke tests for combat resolution and save round-trip

## S3 — World loop

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

## S2 build spec — start here

Goal: **operators become attacks.** After S2 the player can kill things by editing text
correctly under time pressure, earns skill levels for doing it, and keeps progress between
sessions.

### The central mechanic

Mobs are literally text in the map buffer. Killing one means performing the *correct
operator + motion* while the cursor is on it. The engine watches for buffer changes rather
than trying to parse keystrokes — that way any equivalent keystroke path counts, which is
what real fluency looks like.

Implementation sketch:

1. Unlock `modifiable` on the game buffer while the player is in a combat zone.
2. Attach `nvim_buf_attach` (or `on_bytes`) to receive every edit.
3. On each change, diff the affected region against the zone's authored map:
   - text that was a mob and is now gone → **kill**, award XP for the operator used;
   - terrain damaged (wall or floor edited) → **miss**: repaint that region from the
     authored map, small stamina penalty, no HP change.
4. Repaint is authoritative: `zone.map` is the source of truth, the buffer is a view.
   This is what makes wrong edits safe and keeps the world consistent.
5. `state.keylog` (already recording) tells you *which* command was used for skill credit
   and, later, for keystroke-golf par.

### Mob roster (goes in `content/mobs.lua`)

| Mob | Looks like | Killed by | Teaches |
| --- | --- | --- | --- |
| grub | `o` adjacent to you | `x` | single-char delete |
| word-mob | `rot`, `mold`, `blight` | `dw` / `de` | operator + word motion |
| quoted imp | `"imp"` | `di"` / `ci"` | quote text objects |
| bracket troll | `(troll)` | `ca(` / `di(` | bracket text objects |
| line-wraith | a full corrupted line | `dd` / `d$` | line operators |
| swarm | three word-mobs in a row | `3dw` | counts |

Give each a `weakness` field naming the accepted operator(s); anything else is a miss.

### Checklist

- [ ] `content/mobs.lua` schema + roster above; zones reference mobs by key
- [ ] `engine/combat.lua`: buffer-change watcher, kill/miss resolution, terrain repaint
- [ ] Kill feedback: brief highlight flash, floating XP number, combo counter for `.`
- [ ] `systems/skills.lua`: Motion / Operator / Text-object skills, level-ups, `ui/` report
- [ ] `save/init.lua` + `save/migrate.lua`, `schema_version = 1`, `:VimQuest reset`
- [ ] `ui/cheatsheet.lua` on `<F3>`: unlocked commands, built on `ui/panel.lua`
- [ ] Zone 1 "The Rotwood" with a mob teaching each roster entry, plus its exit portal
- [ ] Smoke tests: kill resolution, miss repaint, save round-trip with a version bump

### Acceptance

Play `:VimQuest zone 01_rotwood`: every roster mob can be killed with its intended command,
a wrong edit repairs the map instead of corrupting it, skills level visibly, and quitting
and relaunching restores level and XP.

---

## Known rough edges

- [ ] Zone 0 map is hand-drawn; a zone-width validator should run in CI (currently only
      checked by `tests/smoke.lua`)
- [ ] Maps are ASCII-only by design (byte columns must equal screen cells). Unicode tiles
      need a width-aware renderer before they can be used.
- [ ] `pacer` behaviour is implemented but unused until S2 zones need it.
