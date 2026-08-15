# Changelog

What shipped in each segment, and **why it is shaped the way it is**. Forward-looking work
lives in [TODO.md](TODO.md); the vision and locked decisions live in [DESIGN.md](DESIGN.md).
This file is the record of decisions that are already spent — read it when something in the
code looks arbitrary and you want to know whether it was.

Each segment ends playable and committed. Dan works in limited-budget sessions.

---

## S3 — World loop (2026-08-15)

`7684afb` feature · `e7f99d0` docs · `4e6362c` docs

Two zones were a corridor. S3 made a world: somewhere to come back to, reasons to go out
again, and a choice about what to train next — the Skyrim-shaped loop from DESIGN.md §4.

**Shipped**

- **Coldbuffer**, the hub (`02_coldbuffer`). Four NPCs with branching dialogue, a bounty
  board, a shrine, and portals to everywhere else.
- **`systems/quests.lua`** — objectives as data: `kill`, `kill_with`, `clear_zone`, `reach`.
  Two hand-written quests in `content/quests.lua`.
- **`systems/bounties.lua`** — radiant contracts generated from the mob roster.
- **`systems/perks.lua` + `content/perks.lua`** — seven perks, points from character levels
  and quest rewards.
- **`systems/travel.lua`** — shrines bound with `ma`, returned to with `'a`, across zones.
- **`ui/menu.lua`, `ui/converse.lua`, `ui/board.lua`, `ui/questlog.lua` (`<F4>`),
  `ui/skilltree.lua` (`<F5>`)**.
- **Zone 3 "The Long Ledger"** — `0 ^ $`, `f t ; ,`, counts, across corridors too long to walk.
- **Zone 4 "The Nested Vaults"** — `di(` vs `da(`, vault seals needing `2di(`, and the
  Nested Heart boss needing `3ci(`.
- **Save `schema_version = 2`** with its migration from 1.

**Why it is shaped this way**

- **`safe = true` is a zone flag, not a check on a zone id.** The hub needed "no damage",
  and the temptation was one `if zone.id == "02_coldbuffer"`. That would have made the next
  sanctuary a second special case. Named flags are now invariant 10.
- **Systems never know about specific content.** The engine reports events — a kill, a zone
  cleared, a zone entered — and `quests.lua` decides whether anything cares. This is the
  only reason a bounty can be *generated at runtime* and still be an ordinary quest.
- **A radiant quest carries its own definition** on the quest record. Bounties have no entry
  in `content/quests.lua`, so without this they could not survive a save.
- **Fast travel is literally marks.** `m`, `'` and `` ` `` are intercepted and read the next
  character themselves. A menu of destinations would have been easier and would have taught
  nothing — DESIGN.md §2 says the mechanic must *be* the keystroke, not stand for it.
- **One menu component.** Conversations, the board and the skill tree are `ui/menu.lua` with
  different data, so selection behaves identically everywhere. Its keys are `j`/`k`/`<CR>`
  deliberately: even the menus drill the curriculum.
- **The composition boss needed no engine work.** The `weakness` matcher from S2 already
  handled counts, so `3ci(` was a data entry in `content/mobs.lua`. That is the test of
  whether the S2 extension points were right, and they were.
- **No perk gates a zone**, though the S3 spec asked for one. A gate breaks the ten-minute
  pop-in session, which is a locked decision. Recorded as an open question instead.

**Found while building**

- The zone loader silently dropped the `travel` flag on exits, so hub portals would have
  shown a ZONE CLEARED summary instead of walking you through. The smoke test caught it.

---

## S2 — Combat and progression (2026-08-14)

`0efb650` feature · `843c42b` docs

Operators became attacks. This is the segment where the drill becomes the game.

**Shipped**

- **`engine/combat.lua`** — the buffer is unlocked in combat zones and every edit is
  watched. Kill/miss resolution, authoritative repaint, combo meter, `.` credited to the
  strike it repeats.
- **`content/mobs.lua`** — grub (`x`), blight-word (`dw`/`de`), quoted imp (`di"`), bracket
  troll (`ca(`), line-wraith (`dd`), swarm (`3dw`).
- **`systems/skills.lua`** — Motion / Operator / Text-object / Count level by use; character
  level derives from the average and grants max health.
- **`save/`** with `schema_version = 1`, `migrate.lua`, autosave, `:VimQuest reset`.
- **`ui/cheatsheet.lua`** (`<F3>`), unlocking as skills come into use.
- **Zone 1 "The Rotwood"** — nine rooms, one lesson each.

**Why it is shaped this way**

- **Combat judges the buffer, not the keystrokes.** Whether something died is decided by
  looking at what changed; the keylog only decides *which* command earned the credit.
  Judging by keystrokes would mean blessing one way to perform each edit, which is the
  opposite of teaching fluency — `dw`, `2dw` from a different cell and `cw`+`<Esc>` must all
  count, and they do.
- **The authored map is the truth; the buffer is a view of it.** Every edit is followed by a
  repaint from `zone.map`. This is not a safety net bolted on afterwards — it is the reason
  a beginner can flail at the text with no consequence, which the whole design rests on.
  Nothing may depend on player edits persisting. Invariant 8.
- **Weaknesses match the *tail* of the keys** since the last change, so approach motions in
  front of a strike are ignored and `lllldw` still reads as `dw`.
- **Mobs are authored as a run of their legend character** exactly as long as their body.
  The footprint is visible in the map and a mistyped run is a load-time error rather than a
  silently shifted row.

**Found while building — both cost real time, both are now in DESIGN.md §7**

- **`vim.on_key` reports Neovim's internal key expansion.** Pressing `x` really feeds
  `x`, `d`, `l`. This overcharged stamina three times over and made combat misread every
  command, because the tail of the keylog was `"xdl"` and matched nothing. Only keys with a
  non-empty `typed` argument are player input. This will matter again for keystroke-golf
  par in S4.
- **Strikes must be judged by byte region (`on_bytes`), not by comparing text.** Deleting
  one grub shifts the rest of its line left, and content comparison then reported every mob
  to its right as attacked. A single `x` was killing two grubs.

---

## S1.1 — Readability patch (2026-08-14)

`a20c56e` · `5a44417`

A playtest of Zone 0 found two things that made the game unfinishable rather than merely
rough: there was no exit, so the player could not tell how to finish, and statusline
messages vanished before they could be read.

- Modal dialogue panels — the world freezes while you read, dismissed with `<CR>`.
- Journal (`<F1>`) — re-read everything said this run.
- Opening briefing panel: goal and controls before the zone starts.
- Exit portal `>` and a ZONE CLEARED summary.
- `ui/panel.lua`, the one floating panel every later UI is built on.

**The lesson, kept in DESIGN.md §7 so it is not re-litigated:** any text longer than a few
words needs a panel, and every zone needs a visible, stated goal. Reading is never timed —
invariant 6.

---

## S1 — Engine core (2026-08-14)

`7a6618c` · `67695f0`

- Repo scaffold, MIT, isolated launcher (`NVIM_APPNAME=vimquest`).
- Grid/coords, tick loop, focus auto-pause.
- `CursorMoved` wall collision — the cursor is the player, movement is never simulated.
- Entity spawning with named `behaviours` as the extension point.
- Keystroke recorder, stamina economy.
- Declarative zone loader with in-map legend positioning — positions are authored in the
  map, never as coordinate numbers, so nobody counts columns.
- Zone 0 "The Awakening", and the headless smoke test.

**Why it is shaped this way:** the isolation requirement (`NVIM_APPNAME`) was a launch
condition from Dan — his real config must never be at risk. The engine/content split was
absolute from the first commit, which is what let S2 and S3 add mobs, quests, NPCs and
perks without rewriting anything underneath.
