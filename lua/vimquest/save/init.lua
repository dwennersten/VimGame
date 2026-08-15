-- Persistence.
--
-- The only files VimQuest is ever allowed to write live under
-- stdpath("data")/vimquest/. Game buffers are scratch and the player's own
-- files are never touched - that is a hard invariant, not a preference.
--
-- Only progression is persisted: skills, character xp, zones cleared, lifetime
-- totals. Anything that belongs to a single run stays in state.lua.

local state = require("vimquest.state")
local config = require("vimquest.config")
local migrate = require("vimquest.save.migrate")

local M = {}

M.SCHEMA_VERSION = migrate.SCHEMA_VERSION

---@return string
function M.dir()
  return config.options.save.dir or vim.fs.joinpath(vim.fn.stdpath("data"), "vimquest")
end

---@return string
function M.path()
  return vim.fs.joinpath(M.dir(), "save.json")
end

---@return boolean
function M.exists()
  return vim.fn.filereadable(M.path()) == 1
end

---The current run's progression, ready to serialise.
---@return table
function M.snapshot()
  return {
    schema_version = M.SCHEMA_VERSION,
    saved_at = os.time(),
    skills = require("vimquest.systems.skills").serialise(),
    quests = require("vimquest.systems.quests").serialise(),
    perks = require("vimquest.systems.perks").serialise(),
    shrines = require("vimquest.systems.travel").serialise(),
    perk_bonus = state.perk_bonus,
    player = { xp = state.player and state.player.xp or 0 },
    zones_cleared = vim.deepcopy(state.zones_cleared),
    stats = vim.deepcopy(state.stats),
  }
end

---Write progression to disk.
---@return boolean ok, string|nil err
function M.write()
  if not config.options.save.enabled then
    return false, "saving disabled"
  end
  local ok, encoded = pcall(vim.json.encode, M.snapshot())
  if not ok then
    return false, tostring(encoded)
  end
  vim.fn.mkdir(M.dir(), "p")
  -- writefile() returns 0 on success, so both the call and its result matter.
  local called, result = pcall(vim.fn.writefile, { encoded }, M.path())
  if not called or result ~= 0 then
    return false, "could not write " .. M.path()
  end
  return true, nil
end

---Read progression from disk, migrating it forward if it is older.
---@return table|nil data, string|nil err
function M.read()
  if not M.exists() then
    return nil, nil
  end
  local ok, contents = pcall(vim.fn.readfile, M.path())
  if not ok or not contents or #contents == 0 then
    return nil, "save file is unreadable"
  end
  local decoded_ok, data = pcall(vim.json.decode, table.concat(contents, "\n"))
  if not decoded_ok or type(data) ~= "table" then
    return nil, "save file is not valid JSON"
  end
  local migrated, err = migrate.run(data)
  if err then
    return nil, err
  end
  return migrated, nil
end

---Load progression into the live state. Safe to call on a fresh install.
---@return boolean loaded
function M.load_into_state()
  local skills = require("vimquest.systems.skills")
  local quests = require("vimquest.systems.quests")
  local perks = require("vimquest.systems.perks")
  local travel = require("vimquest.systems.travel")

  -- Start from a clean slate either way, so a failed or missing load leaves a
  -- consistent new game rather than whatever the last run left behind.
  skills.restore(nil)
  quests.restore(nil)
  perks.restore(nil)
  travel.restore(nil)
  state.perk_bonus = 0
  if not config.options.save.enabled then
    perks.apply()
    return false
  end

  local data, err = M.read()
  if err then
    vim.notify("VimQuest: " .. err .. " - starting a fresh run.", vim.log.levels.WARN)
    perks.apply()
    return false
  end
  if not data then
    perks.apply()
    return false
  end

  skills.restore(data.skills)
  quests.restore(data.quests)
  perks.restore(data.perks)
  travel.restore(data.shrines)
  state.perk_bonus = tonumber(data.perk_bonus) or 0
  state.zones_cleared = type(data.zones_cleared) == "table" and data.zones_cleared or {}
  local stats = type(data.stats) == "table" and data.stats or {}
  state.stats = {
    kills = tonumber(stats.kills) or 0,
    misses = tonumber(stats.misses) or 0,
    best_combo = tonumber(stats.best_combo) or 0,
  }
  if state.player then
    state.player.xp = tonumber(data.player and data.player.xp) or 0
  end
  -- perks.apply() ends by calling skills.apply_to_player(), so health reflects
  -- both levels and perks.
  perks.apply()
  return true
end

---Delete the save file. Used by `:VimQuest reset`.
---@return boolean ok
function M.delete()
  if not M.exists() then
    return true
  end
  return pcall(vim.fn.delete, M.path()) and vim.fn.filereadable(M.path()) == 0
end

return M
