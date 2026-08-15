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
| `<Esc><Esc>` | leave the world |
| `<F2>` | pause |
| `:VimQuest` | enter the world |
| `:VimQuest quit` | stop the game |
| `:VimQuest zone 00_awakening` | jump to a zone |

### As a plugin in your own config

```lua
{ "dwennersten/vimquest.nvim", opts = {} }   -- lazy.nvim
```

## Design

- **Text is the world.** Walls block the cursor, `f<char>`/`$` are blink-dashes, and from
  segment S2 operators are attacks: `dw` kills a word-mob, `di"` a caged demon, `ca(` a
  bracket beast, `3dw` is a three-hit combo.
- **Skill-by-use progression.** Using motions levels Motion; using operators levels
  Operator. Levels grant perk points that unlock abilities and zones.
- **Stamina punishes spam.** Mashing `jjjjjj` drains stamina and eventually costs HP;
  `5j` or `}` is nearly free. The economy is designed to prevent the worst vim habit.
- **Radiant bounties** give 5–10 minute pop-in sessions; zones and bosses give long ones.
- **Adaptive difficulty.** Fumbled commands are tracked and resurface as targeted bounties.

## Roadmap

| Segment | Contents | Status |
| --- | --- | --- |
| S1 | engine core, tick loop, collision, HUD, Zone 0 | ✅ done |
| S2 | operator combat, mobs, skills/XP, saves, cheat panel, Zone 1 "The Rotwood" | next |
| S3 | hub town, quests, radiant bounties, skill tree UI, first boss | planned |
| S4 | keystroke-golf scoring, ghost replays, adaptive spawns, spaced repetition | planned |
| S5 | registers/marks/macros zones, config-quest guild, real-file endgame zones | planned |
| S6 | tests + CI, `:checkhealth`, docs, daily seeded challenge, achievements | planned |

## Contributing content

Zones are data, not code. See [CONTENT.md](CONTENT.md) — adding a zone is one file and
never touches the engine.

MIT licensed.
