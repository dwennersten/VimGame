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

Register the id in the `:VimQuest` completion list in `plugin/vimquest.lua`.

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
| `config.lua` | all tunables (tick rate, damage, stamina costs) |
| `state.lua` | runtime singleton, `reset()`, `say()` |
| `engine/grid.lua` | coordinates, walkability, cursor conversion |
| `engine/render.lua` | tabpage/buffer lifecycle, highlights, entity overlays |
| `engine/collision.lua` | `CursorMoved` wall guard |
| `engine/input.lua` | keystroke recorder + stamina charging |
| `engine/entity.lua` | spawning and behaviours |
| `engine/tick.lua` | world clock, damage, triggers |
| `ui/hud.lua` | winbar vitals + statusline messages |
| `content/zones/` | zone data files |
