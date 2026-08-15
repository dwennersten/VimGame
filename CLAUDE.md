# CLAUDE.md — orientation for a new session

**VimQuest** is a real-time dark-fantasy RPG that runs *inside real Neovim*, built to teach
its player (Dan) vim to a proficient level. The cursor is the player, buffer text is the
world, and vim commands are the combat system.

Read these before changing anything:

| File | What it answers |
| --- | --- |
| `DESIGN.md` | **The whole vision and why.** Locked decisions, vim-verb → game-verb mapping, progression model, curriculum map. Read this first. |
| `TODO.md` | **What to build next.** Segment checklist; S2 has a full build spec at the bottom. |
| `CONTENT.md` | Zone data schema, behaviours, module map. Needed for any content work. |
| `suggested_features.md` | The 22 accepted features with rationale (F-numbers referenced from TODO). |

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
lands in S6.

## Module map (short form — full table in CONTENT.md)

```
lua/vimquest/
  init.lua        setup/start/quit/complete + keymaps
  config.lua      every tunable (tick rate, damage, stamina costs)
  state.lua       runtime singleton, say(), reset()
  engine/         grid, tick, collision, entity, render, input
  ui/             panel (base), dialogue, journal, hud
  content/zones/  data files + loader
```

## About the player

Dan is new to Neovim (it was not installed before this project) and wants to reach
proficiency across motions, operators, text objects, registers, macros and Neovim-specific
workflow. He likes open-world action RPGs with level progression (Skyrim, Valheim), values
being able to pop in for 10 minutes *or* sink hours, and asked that the project stay easy
for a future Claude Code session to extend. Design for engagement, but the learning is the
point — gameplay serves the curriculum.
