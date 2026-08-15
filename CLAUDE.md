# CLAUDE.md — orientation for a new session

**VimQuest** is a real-time dark-fantasy RPG that runs *inside real Neovim*, built to teach
its player (Dan) vim to a proficient level. The cursor is the player, buffer text is the
world, and vim commands are the combat system.

Read these before changing anything:

| File | What it answers |
| --- | --- |
| `DESIGN.md` | **The whole vision and why.** Locked decisions, vim-verb → game-verb mapping, progression model, curriculum map. Read this first. |
| `TODO.md` | **What to build next.** Segment checklist; S4 has a full build spec at the bottom, above it short "what S2/S3 delivered" sections explaining how combat and the world loop work. |
| `CONTENT.md` | Zone, mob, NPC, quest and perk schemas; the save file; module map. Needed for any content work. |
| `CHANGELOG.md` | **What already shipped and why.** Read it when something in the code looks arbitrary and you want to know whether it was. |
| `suggested_features.md` | The 22 accepted features with rationale (F-numbers referenced from TODO). |

## Starting a session

1. **Run the smoke test first** (command below). It should print `SMOKE PASS` — 43 checks
   as of S3. A green baseline before you touch anything tells you whether a later failure
   is yours.
2. **Read the "what S2/S3 delivered" sections in `TODO.md`.** They explain how combat and
   the world loop actually work, and they exist so you do not re-derive it from the source.
3. **Pick up at the first unchecked box** in the lowest open segment of `TODO.md`. S4 has a
   full build spec at the bottom of that file.

Before you finish: smoke test green, boxes ticked, `README.md` roadmap in sync, `CHANGELOG.md`
given a section if a segment shipped, and a commit with a real message body.

## Working agreement

- **Pick up work** at the first unchecked box in the lowest open segment of `TODO.md`.
  Tick boxes as they land and keep the roadmap table in `README.md` in sync.
- **Segment discipline.** Each segment must end playable and committed. Dan works in
  limited-budget sessions, so prefer finishing one segment well over starting three.
- **Content is data, never code.** Adding zones/mobs/quests must not require engine edits.
  If it does, that is a bug in the engine's extension points — fix the engine.
- **Commit** at the end of each segment with a real message body (use `git commit -F` — a
  `-m` string containing quotes breaks PowerShell native-arg passing on this machine).

## Hard invariants — violating these breaks the game

1. **The player IS the cursor.** Never simulate movement. Motions must be genuine vim
   keys, because 100% skill transfer is the entire point of building this in Neovim.
2. **Maps are ASCII only.** Byte columns must equal screen cells or collision and extmark
   overlays desync. A Unicode tileset needs a width-aware renderer first.
3. **Coordinates are 0-indexed** for `row`/`col` everywhere in the engine (`nvim_buf_*`
   convention). Cursor APIs are 1-indexed for rows; convert only in `engine/grid.lua`.
4. **Never write to the user's files.** Game buffers are scratch (`buftype=nofile`,
   `bufhidden=wipe`). The only writes allowed are saves under `stdpath("data")/vimquest/`.
5. **Isolation.** The game launches with `NVIM_APPNAME=vimquest`. It must never read or
   modify a real `~/AppData/Local/nvim` config. This was a launch condition from Dan.
6. **Reading is never timed.** Any panel (`ui/panel.lua`) sets `state.dialog_open`, and
   `engine/tick.lua` freezes the world while it is true. No damage while reading.
7. **`<Esc><Esc>` always exits.** A real-time game inside someone's editor needs a
   guaranteed escape hatch.
8. **The map is the truth; the buffer is a view of it.** `engine/combat.lua` repaints from
   `zone.map` after every edit. This is what makes a wrong strike safe, so never let a
   feature depend on the buffer holding player edits.
9. **Never wipe saved progress.** Bumping `SCHEMA_VERSION` in `save/migrate.lua` requires
   a migration from the previous version in the same commit.
10. **New engine capabilities are named zone flags**, never a check on a zone id.
    `safe = true` and `combat = true` are the pattern to copy.

## Commands

```powershell
# Play (installed Neovim 0.12.4 at "$env:ProgramFiles\Neovim\bin\nvim.exe")
powershell -File scripts\play.ps1

# Headless smoke test — run this after every engine change
$env:NVIM_APPNAME='vimquest'
& "$env:ProgramFiles\Neovim\bin\nvim.exe" --headless -u init.lua -c "luafile tests/smoke.lua"
# exits 0 on SMOKE PASS
```

Grow `tests/smoke.lua` alongside features; it is the only regression net until plenary
lands in S6. Three things about it are not obvious from reading it:

- **Combat tests press real keys**, via `nvim_feedkeys(keys, "xt", false)`. The `t` matters:
  without it the keys arrive untyped and `engine/input.lua` correctly ignores them, so the
  strike lands in the buffer but combat never sees a command and every kill reads as a miss.
- **Saving is redirected** to a temp directory by `vq.setup({ save = { dir = ... } })` at
  the top of the file. Never let a test run write to the real save path.
- **Adding a zone means adding its id to `ALL_ZONES`**, which drives the structural checks:
  row widths, walkable spawn, exits that are standable and point at zones that exist,
  reachable NPCs and shrines, and no mob embedded in a wall.

## Keys already claimed

Check here before binding anything new. All are buffer-local to the game buffer, and every
one is bound in `set_keymaps` in `init.lua` except where noted.

| Key | Does | Implemented in |
| --- | --- | --- |
| `<Esc><Esc>` | quit — invariant 7, never rebind | `init.lua` |
| `<F1>` | journal | `ui/journal.lua` |
| `<F2>` | pause | `init.lua` |
| `<F3>` | cheatsheet | `ui/cheatsheet.lua` |
| `<F4>` | quest log | `ui/questlog.lua` |
| `<F5>` | skill tree | `ui/skilltree.lua` |
| `m` `'` `` ` `` | shrine binding and fast travel | bound by `systems/travel.lua:attach` |
| `j` `k` `<CR>` `1`–`9` | menu selection, inside panels only | `ui/menu.lua` |
| `<CR>` `<Esc>` `q` | dismiss a panel | `ui/panel.lua` |

`<F6>` onward is free. Everything else the player presses is meant to reach vim untouched —
that is the entire premise, so intercept a key only when the game genuinely redefines it.

## Module map (short form — full table in CONTENT.md)

```
lua/vimquest/
  init.lua        setup/start/quit/complete/reset + keymaps
  config.lua      every tunable (tick rate, damage, stamina, combat, saving)
  state.lua       runtime singleton, say(), reset()
  engine/         grid, tick, collision, entity, combat, render, input
  systems/        skills, quests, bounties, perks, travel
  save/           init (read/write) + migrate (schema versions)
  ui/             panel + menu (bases), dialogue, journal, cheatsheet,
                  questlog, skilltree, converse, board, hud
  content/        mobs, commands, quests, perks, zones/ (data + loader)
```

Zone map: `00_awakening → 01_rotwood → 02_coldbuffer ⇄ {03_ledger, 04_vaults}`.
Coldbuffer is the hub — safe, no clock, four NPCs, a shrine and a bounty board.

Two kinds of creature, easy to confuse: **entities** are glyphs drawn over the map as
extmarks and they move (`engine/entity.lua`); **text-mobs** are real buffer text and they
are killed by editing them (`engine/combat.lua`). Entities are the clock, mobs are the
lesson.

## About the player

Dan is new to Neovim (it was not installed before this project) and wants to reach
proficiency across motions, operators, text objects, registers, macros and Neovim-specific
workflow. He likes open-world action RPGs with level progression (Skyrim, Valheim), values
being able to pop in for 10 minutes *or* sink hours, and asked that the project stay easy
for a future Claude Code session to extend. Design for engagement, but the learning is the
point — gameplay serves the curriculum.
