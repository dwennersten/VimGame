-- Save-file migrations.
--
-- Every save carries a `schema_version`. When the shape of the data changes,
-- bump SCHEMA_VERSION and add a migration from the previous number here. A
-- player's progress must survive an update; wiping it is never an option.
--
-- A migration takes the whole save table at version N and returns it at N+1.

local M = {}

M.SCHEMA_VERSION = 2

---@type table<integer, fun(data: table): table>
M.migrations = {
  -- Version 0 means "written before saves were versioned". No such file has
  -- ever shipped, but the path exists so the loader never has a dead end.
  [0] = function(data)
    return {
      skills = type(data.skills) == "table" and data.skills or {},
      player = type(data.player) == "table" and data.player or {},
      zones_cleared = type(data.zones_cleared) == "table" and data.zones_cleared or {},
      stats = type(data.stats) == "table" and data.stats or {},
    }
  end,

  -- 1 -> 2 (S3): quests, perks and bound shrines join the save. A version 1
  -- file predates all three, so they start empty and nothing is lost.
  [1] = function(data)
    data.quests = {}
    data.perks = {}
    data.perk_bonus = 0
    data.shrines = {}
    return data
  end,
}

---Bring a loaded save up to the current schema.
---@param data table
---@return table data, string|nil error
function M.run(data)
  local version = tonumber(data.schema_version) or 0
  if version > M.SCHEMA_VERSION then
    return data, ("save was written by a newer VimQuest (schema %d > %d)"):format(version, M.SCHEMA_VERSION)
  end
  while version < M.SCHEMA_VERSION do
    local step = M.migrations[version]
    if not step then
      return data, ("no migration from schema %d"):format(version)
    end
    data = step(data)
    version = version + 1
  end
  data.schema_version = M.SCHEMA_VERSION
  return data, nil
end

return M
