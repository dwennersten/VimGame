# VimQuest — The Corrupted Buffer

A real-time dark-fantasy RPG that runs **inside real Neovim**, built to teach vim by playing it.

You are the cursor. The text is the world. Vim commands are the combat system — so every
keystroke you learn in the game is a keystroke that works in your editor tomorrow.

```
################################################################
#..............#.........................#.....................#
#..THE.CRYPT...#.........................#....THE.LONG.HALL....#
#..............#.........................#.....................#
#....@.........+.........................#.....................#
################################################################
 VQ  HP [##########] 10/10   STA [########--]   LVL 1  XP 0    The Awakening
```

## Why not a browser game

Browser vim games simulate keys. Simulation drifts from real vim on exactly the edge cases
that matter (counts, operator-pending, text objects). Here the keys *are* vim, because the
game is a Neovim plugin. Bonus: the repo doubles as a small readable Neovim distro, so
learning the game teaches config structure too.

## Install & play

Requires Neovim ≥ 0.10.

```powershell
winget install Neovim.Neovim
git clone <this repo> VimGame
cd VimGame
pwsh scripts/play.ps1        # macOS/Linux: sh scripts/play.sh
```

`play.ps1` sets `NVIM_APPNAME=vimquest`, so the game runs in its own isolated Neovim
profile. **Your real `nvim` config is never read or written.**

Inside the game:

| Key | Meaning |
| --- | --- |
| `hjkl` `w` `b` `e` `0` `$` `gg` `G` | move (you are the cursor) |
| `x` `dw` `di"` `ca(` `dd` `3dw` `.` | attack (the mob decides which one works) |
| `<F1>` | journal — re-read every message from this run |
| `<F2>` | pause |
| `<F3>` | cheatsheet — every command you have learned, plus your skill levels |
| `<F4>` | quest log |
| `<F5>` | skill tree — spend perk points |
| `ma` / `'a` | bind a shrine to a mark / travel back to it from any zone |
| `<CR>` / `<Esc>` | dismiss a panel |
| `<Esc><Esc>` | leave the world |
| `:VimQuest` | enter the world |
| `:VimQuest quit` | stop the game |
| `:VimQuest zone 02_coldbuffer` | jump to a zone |
| `:VimQuest reset` | erase saved progress (asks first) |

### As a plugin in your own config

```lua
{ "dwennersten/vimquest.nvim", opts = {} }   -- lazy.nvim
```

## Design

- **Text is the world.** Walls block the cursor, `f<char>`/`$` are blink-dashes, and
  operators are attacks: `dw` kills a blight-word, `di"` a caged imp, `ca(` a bracket troll,
  `dd` a line-wraith, `3dw` a swarm. The engine watches the *buffer*, not your keystrokes,
  so any path that produces the right edit counts.
- **Wrong edits are free.** The authored map is the source of truth and the buffer is only
  a view of it, so a miss repaints the world and costs a little stamina. You cannot break
  anything by experimenting — which is the point.
- **Skill-by-use progression.** Using motions levels Motion; using operators levels
  Operator; text objects and counts have their own tracks. Levels grant perk points that
  unlock abilities and zones.
- **Stamina punishes spam.** Mashing `jjjjjj` drains stamina and eventually costs HP;
  `5j` or `}` is nearly free. The economy is designed to prevent the worst vim habit.
- **Radiant bounties** give 5–10 minute pop-in sessions; zones and bosses give long ones.
- **Fast travel is marks.** `ma` on a shrine binds it, `'a` returns from any zone. Nothing
  in the game is a metaphor for a keystroke — it *is* the keystroke.
- **Adaptive difficulty.** Fumbled commands are tracked and resurface as targeted bounties.

## The world so far

```
00_awakening  →  01_rotwood  →  02_coldbuffer  ⇄  03_ledger
   the cursor      operators        the hub      ⇄  04_vaults
```

**Coldbuffer** is the hub: nothing there can hurt you, and four people are worth talking
to. The Warden and the Archivist give quests, the Trainer sells perks and patches you up,
the Board-keeper runs a bounty board that never runs out. Walk into someone to talk.

**The Rotwood** teaches operators, **The Long Ledger** teaches line anchors and character
search across corridors too long to walk, and **The Nested Vaults** ends in a boss that is
not a new command — just three known ones said in one breath (`3ci(`).

## Roadmap

| Segment | Contents | Status |
| --- | --- | --- |
| S1 | engine core, tick loop, collision, HUD, Zone 0 | ✅ done |
| S1.1 | dialogue panels, journal, opening briefing, exit portal + zone summary | ✅ done |
| S2 | operator combat, mobs, skills/XP, saves, cheat panel, Zone 1 "The Rotwood" | ✅ done |
| S3 | hub town, quests, radiant bounties, skill tree, marks, zones 2–3 + boss | ✅ done |
| S4 | keystroke-golf scoring, ghost replays, adaptive spawns, spaced repetition | next |
| S5 | registers/marks/macros zones, config-quest guild, real-file endgame zones | planned |
| S6 | tests + CI, `:checkhealth`, docs, daily seeded challenge, achievements | planned |

### Documentation

| File | Contents |
| --- | --- |
| [DESIGN.md](DESIGN.md) | The vision: locked decisions, vim-verb → game-verb mapping, progression model, curriculum map, playtest findings |
| [TODO.md](TODO.md) | Build checklist per segment, plus a full S4 build spec |
| [CHANGELOG.md](CHANGELOG.md) | What shipped in each segment and why it is shaped that way |
| [CONTENT.md](CONTENT.md) | Zone, mob, NPC, quest and perk schemas; behaviours; module map |
| [CLAUDE.md](CLAUDE.md) | Orientation and hard invariants for an AI session |
| [suggested_features.md](suggested_features.md) | The 22 accepted features and why |

## Finishing a zone

Each zone has an exit portal (`>`). Step onto it and a ZONE CLEARED panel reports your
time, keystrokes, kills and skill levels, then offers `n` for the next zone, `r` to replay
or `<CR>` to leave. Messages never scroll away: the world freezes while a panel is open,
and `<F1>` reopens the full journal.

Progress — skill levels, xp, zones cleared — is saved to
`stdpath("data")/vimquest/save.json` and restored on the next run. `:VimQuest reset` erases
it. That file is the **only** thing VimQuest ever writes; game buffers are scratch and your
own files are never touched.

## Contributing content

Zones are data, not code. See [CONTENT.md](CONTENT.md) — adding a zone is one file and
never touches the engine.

MIT licensed.
