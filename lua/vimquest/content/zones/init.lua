-- Zone loader.
--
-- Zone files are pure data. Positions are authored *in the map itself* using
-- legend characters (e.g. "@" for spawn, "g" for a mob), which the loader
-- extracts and then paints over with floor. That means adding content never
-- requires counting columns by hand, and never requires touching engine code.
--
-- Text-mobs are authored the same way, as a RUN of the legend character whose
-- length equals the mob's body: `rrr` for a three-letter blight-word. You can
-- see a mob's footprint in the map, and the loader rejects a run of the wrong
-- length rather than silently shifting the row.

local mobs = require("vimquest.content.mobs")

local M = {}

---Build one text-mob from a legend entry.
---@param entry table legend entry with type == "mob"
---@param id string zone id, for error messages
---@return table def with `text` resolved
local function mob_def(entry, id)
  local base = entry.mob and mobs.get(entry.mob)
  if entry.mob and not base then
    error(("VimQuest: zone '%s' references unknown mob '%s'"):format(id, entry.mob))
  end
  local def = vim.tbl_extend("force", base or {}, entry)
  def.type = nil
  def.mob = entry.mob
  if not def.text or def.text == "" then
    error(("VimQuest: zone '%s' has a mob with no text"):format(id))
  end
  return def
end

---@param id string zone id, e.g. "00_awakening"
---@return table zone runtime-ready zone (map cleaned, entities/triggers/mobs extracted)
function M.load(id)
  local ok, raw = pcall(require, "vimquest.content.zones." .. id)
  if not ok then
    error("VimQuest: unknown zone '" .. id .. "' (" .. tostring(raw) .. ")")
  end

  local zone = vim.deepcopy(raw)
  zone.id = zone.id or id
  zone.solid = zone.solid or "#"
  zone.floor = zone.floor or "."
  zone.entities = {}
  zone.triggers = {}
  zone.exits = {}
  zone.mobs = {}
  zone.npcs = {}
  zone.shrines = {}

  local legend = zone.legend or {}
  local map = {}

  for r, line in ipairs(zone.map) do
    local chars = {}
    local c = 1
    while c <= #line do
      local ch = line:sub(c, c)
      local entry = legend[ch]
      local row, col = r - 1, c - 1

      if entry and entry.type == "mob" then
        -- Consume the whole run of this character; it must match the body length.
        local run = 0
        while line:sub(c + run, c + run) == ch do
          run = run + 1
        end
        local def = mob_def(entry, zone.id)
        if run ~= #def.text then
          error(
            ("VimQuest: zone '%s' row %d: mob '%s' needs a run of %d '%s' (found %d)")
              :format(zone.id, r, def.name or ch, #def.text, ch, run)
          )
        end
        def.row, def.col = row, col
        table.insert(zone.mobs, def)
        for i = 0, run - 1 do
          chars[c + i] = zone.floor
        end
        c = c + run
      else
        if entry then
          if entry.type == "spawn" then
            zone.spawn = { row = row, col = col }
          elseif entry.type == "trigger" then
            table.insert(zone.triggers, {
              row = row,
              col = col,
              text = entry.text,
              title = entry.title,
              quiet = entry.quiet,
            })
          elseif entry.type == "exit" then
            table.insert(zone.exits, {
              row = row,
              col = col,
              to = entry.to,
              travel = entry.travel,
              title = entry.title,
              text = entry.text,
            })
          elseif entry.type == "entity" then
            local spec = vim.tbl_extend("force", vim.deepcopy(entry), { row = row, col = col })
            spec.type = nil
            table.insert(zone.entities, spec)
          elseif entry.type == "npc" then
            local npc = vim.tbl_extend("force", vim.deepcopy(entry), { row = row, col = col })
            npc.type = nil
            npc.id = npc.id or ("npc_" .. #zone.npcs + 1)
            table.insert(zone.npcs, npc)
          elseif entry.type == "shrine" then
            table.insert(zone.shrines, {
              row = row,
              col = col,
              name = entry.name or "shrine",
              text = entry.text,
            })
          end
          chars[c] = entry.leaves or zone.floor
        else
          chars[c] = ch
        end
        c = c + 1
      end
    end
    map[r] = table.concat(chars)
  end

  zone.map = map
  zone.legend = nil
  zone.spawn = zone.spawn or { row = 0, col = 0 }
  -- A zone is a combat zone if it says so, or simply if it contains text-mobs.
  if zone.combat == nil then
    zone.combat = #zone.mobs > 0
  end
  return zone
end

return M
