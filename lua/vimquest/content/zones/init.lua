-- Zone loader.
--
-- Zone files are pure data. Positions are authored *in the map itself* using
-- legend characters (e.g. "@" for spawn, "g" for a mob), which the loader
-- extracts and then paints over with floor. That means adding content never
-- requires counting columns by hand, and never requires touching engine code.

local M = {}

---@param id string zone id, e.g. "00_awakening"
---@return table zone runtime-ready zone (map cleaned, entities/triggers extracted)
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

  local legend = zone.legend or {}
  local map = {}

  for r, line in ipairs(zone.map) do
    local chars = {}
    for c = 1, #line do
      local ch = line:sub(c, c)
      local entry = legend[ch]
      if entry then
        local row, col = r - 1, c - 1
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
            title = entry.title,
            text = entry.text,
          })
        elseif entry.type == "entity" then
          local spec = vim.tbl_extend("force", vim.deepcopy(entry), { row = row, col = col })
          spec.type = nil
          table.insert(zone.entities, spec)
        end
        chars[c] = entry.leaves or zone.floor
      else
        chars[c] = ch
      end
    end
    map[r] = table.concat(chars)
  end

  zone.map = map
  zone.legend = nil
  zone.spawn = zone.spawn or { row = 0, col = 0 }
  return zone
end

return M
