# VimQuest — design document

The complete vision, the decisions behind it, and the curriculum it has to deliver.
If a future change contradicts something here, that is a design change: update this file
in the same commit.

---

## 1. The premise

vim-adventures.com proved that learning vim as a game works, but it runs in a browser with
*simulated* keys. Simulation drifts from real vim exactly where it matters — counts,
operator-pending mode, text objects — and it teaches nothing about Neovim itself.

VimQuest runs **inside real Neovim**. The cursor is the player. The buffer text is the
world. Vim commands are the combat system. Every keystroke learned in the game is a
keystroke that works in the editor tomorrow, with no translation layer.

Secondary goal: the repo is itself a small, readable Neovim distro, so the player finishes
the game owning a config they understand.

## 2. Locked decisions (and why)

| Decision | Why |
| --- | --- |
| Neovim plugin, not browser | 100% skill transfer; teaches Neovim config as a side effect |
| Isolated `NVIM_APPNAME=vimquest` | The player's real config must never be at risk |
| Text *is* the battlefield | Killing something = editing correctly under pressure; the drill becomes the game |
| Real-time enemies with HP | Player explicitly chose adrenaline over turn-based scoring |
| Skill-by-use progression | Skyrim-shaped: the thing you practise is the thing that levels |
| Config quests are optional | Hard gates would kill the 10-minute pop-in session |
| Adaptive weakness-seeking spawns | Chosen for learning payoff; visible skill report; toggleable |
| Always-available cheat panel | Lowest-friction help; player chose this over discovery-by-experiment |
| Dark fantasy, "The Corrupted Buffer" | Player's pick over cyber/roguelike/comedic |
| ASCII maps, plain Unicode UI | Dev machine has Cascadia Code, no Nerd Font; byte-column safety |
| Public GitHub repo | Player wants it distributable if it works out (confirm name before pushing) |

**Non-goals:** turn-based combat; a vim *emulator* of any kind; mouse support; anything
that writes to the player's real files; content that requires engine edits to add.

## 3. Vim as a combat system

The core mapping. Everything in the game should come from this table, not from invented
mechanics.

| Vim | Game verb | Teaches |
| --- | --- | --- |
| `hjkl` | walk (expensive — drains stamina) | basic movement, and why not to rely on it |
| `w b e` | stride word-wise (cheap) | word motions |
| `0 ^ $` | blink along the line | line anchors |
| `gg G` `{ }` | long-range blink | file/paragraph navigation |
| `f t ; ,` | dash to a landmark char; also crosses gaps | character search |
| `/ ? n N` | scrying — reveals and tracks quest targets | search |
| count prefix | damage/distance multiplier (`3dw` = three-hit combo) | counts |
| `x` | stab an adjacent enemy | single-char delete |
| `dw` `d$` `dd` | slay word-mobs, line-wraiths | operator + motion |
| `ciw` `ci"` `ca(` | purify cursed words, cage demons, bracket beasts | text objects |
| `.` | combo repeat — builds a combo meter | dot repeat |
| `u` `<C-r>` | time-rewind potion (limited charges) | undo tree |
| `y` `p` `"a` | loot to inventory; place bridges/traps | registers |
| `m'` `` ` `` | shrine waypoints, fast travel | marks |
| `q` `@a` | record a ritual, summon it as an ultimate | macros |
| `:s` `:g` | enchanting table; mass banishment | ex commands |
| `v` `V` `<C-v>` | area-of-effect attacks | visual modes |
| `gd` `]d` `:cnext` | endgame: hunting through real code | Neovim workflow |

**Stamina economy.** `hjkl` cost 2 each; efficient motions cost 0.5; empty stamina bleeds
HP. This exists to structurally prevent the single worst vim habit. Tunables live in
`config.lua` under `stamina_cost`.

## 4. Progression model

- **Skill-by-use.** Using motions levels *Motion*; operators level *Operator*; text objects
  level *Text-object*; and so on. No abstract XP bar detached from practice.
- **Perks.** Levels grant points on a tree that unlocks abilities and gates zones.
- **Three session shapes**, deliberately:
  - *10 minutes*: a radiant bounty ("clear 5 bracket-beasts with `ca(`").
  - *30–60 minutes*: a zone, a dungeon, a quest chain.
  - *Open-ended*: exploration, side quests, grinding weak skills — which genuinely makes
    the main quest easier, the Skyrim loop the player asked for.
- **Adaptive difficulty.** Per-command accuracy and speed are tracked from the keystroke
  log; weak commands spawn more of their matching mob and surface as targeted bounties on
  an SM-2-lite review schedule.

## 5. Curriculum map

"Proficient" was defined by the player as all four bands. This is the delivery plan.

| Zone | Name | Teaches | Segment |
| --- | --- | --- | --- |
| 0 | The Awakening | cursor-as-player, `hjkl`, walls, stamina, counts | S1 ✅ |
| 1 | The Rotwood | `x`, `dw`, `de`, `ci"`, `ca(`, `dd`, `.`, counts as combos | S2 ✅ |
| — | Coldbuffer (hub) | safe zone, quests, bounties, skill tree, vendors | S3 |
| 2 | The Long Ledger | `0 ^ $`, `f t ; ,`, `gg G`, `{ }` under pressure | S3 |
| 3 | The Nested Vaults | nested text objects, `di(` vs `da(`, `2ci(` boss | S3 |
| 4 | The Register Vaults | `y p "a`, marks and fast travel | S5 |
| 5 | The Ritual Halls | macros: `qa … q`, `@a`, `@@`, counted replays | S5 |
| 6 | The Transmutation Yard | `:s` with regex, `:g`, ranges | S5 |
| 7 | The Forge (guild) | real config edits, runtime-validated | S5 |
| 8 | The Living Codebase | real files, `gd`, `]d`, quickfix, splits/buffers | S5 |

Mastery of a band is measured by keystroke-golf par (S4), not by completion.

## 6. Architecture principles

- **Engine / content separation is absolute.** Zones, mobs, quests and perks are
  declarative data in `lua/vimquest/content/`. If new content needs new engine capability,
  add a *named extension point* (like `entity.behaviours`) rather than special-casing.
- **Positions are authored in the map** using legend characters, never as coordinate
  numbers. Nobody should count columns.
- **One state singleton** (`state.lua`), reset on quit. Saves serialise a subset with a
  `schema_version` so updates never wipe progress.
- **Panels are one component** (`ui/panel.lua`). Dialogue, journal, cheatsheet,
  zone-complete, and later the skill tree all build on it, so freeze-the-world behaviour
  and key handling stay consistent.
- **Every panel freezes the world.** Reading is never punished.
- **Combat judges the buffer, not the keystrokes.** Whether something died is decided by
  looking at what changed in the buffer; the keylog only decides *which* command earned the
  credit. Judging by keystrokes would mean picking one blessed way to perform each edit,
  which is exactly the opposite of teaching fluency.
- **The authored map is the source of truth; the buffer is a view of it.** Every edit is
  followed by a repaint from `zone.map`. This is not a safety net bolted on — it is the
  reason a beginner can flail at the text without consequence, which the whole design
  depends on. Nothing may rely on player edits persisting in the buffer.

## 7. Playtest findings

Kept so the same ground is not re-litigated.

- *2026-08-14, Zone 0 first play:* fun, but (a) no exit existed — the player could not tell
  how to finish, and (b) statusline messages vanished before they could be read. Fixed in
  S1.1 with exit portals, a ZONE CLEARED summary, modal dialogue panels, an opening
  briefing, and the `<F1>` journal. **Lesson: any text longer than a few words needs a
  panel, and every zone needs a visible, stated goal.**

### Two engine facts worth not rediscovering

- `vim.on_key` reports Neovim's **internal** key expansion as well as what the player
  pressed — pressing `x` feeds `x`, `d`, `l`. Only keys with a non-empty `typed` argument
  are player input. Getting this wrong overcharges stamina and makes combat misread every
  command, and it will matter again for keystroke-golf par in S4.
- Strikes must be judged by **byte region** (`on_bytes`), not by comparing text. Deleting
  one mob shifts the rest of its line, and content comparison then reports every mob to its
  right as attacked.

## 8. Open questions for later

- How much narrative? Currently signpost-flavoured; no NPC dialogue trees until S3.
- Does the hub need vendors/economy, or are perks enough progression?
- Should death cost anything beyond a checkpoint return once combat exists?
- Multi-file zones (splits as separate rooms) — powerful for teaching windows, but needs a
  renderer that tracks several buffers.
