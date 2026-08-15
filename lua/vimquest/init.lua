-- VimQuest - a real-time RPG that runs inside Neovim, where the cursor is the
-- player and vim commands are the combat system.
--
-- Public API:
--   require("vimquest").setup(opts)
--   require("vimquest").start(zone_id?)
--   require("vimquest").quit()
--   require("vimquest").toggle_pause()

local config = require("vimquest.config")
local state = require("vimquest.state")
local zones = require("vimquest.content.zones")
local render = require("vimquest.engine.render")
local collision = require("vimquest.engine.collision")
local input = require("vimquest.engine.input")
local entity = require("vimquest.engine.entity")
local combat = require("vimquest.engine.combat")
local tick = require("vimquest.engine.tick")
local skills = require("vimquest.systems.skills")
local quests = require("vimquest.systems.quests")
local perks = require("vimquest.systems.perks")
local travel = require("vimquest.systems.travel")
local save = require("vimquest.save")
local hud = require("vimquest.ui.hud")
local panel = require("vimquest.ui.panel")
local dialogue = require("vimquest.ui.dialogue")
local journal = require("vimquest.ui.journal")
local cheatsheet = require("vimquest.ui.cheatsheet")
local questlog = require("vimquest.ui.questlog")
local skilltree = require("vimquest.ui.skilltree")
local converse = require("vimquest.ui.converse")
local board = require("vimquest.ui.board")

local M = {}

M.version = "0.1.0"

---@param opts table|nil
function M.setup(opts)
  config.setup(opts)
  render.setup_highlights()
  return M
end

local function set_keymaps(buf)
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, desc = desc })
  end
  map("<Esc><Esc>", function()
    M.quit()
  end, "VimQuest: leave the world")
  map("<F1>", function()
    journal.toggle()
  end, "VimQuest: journal (everything said so far)")
  map("<F2>", function()
    M.toggle_pause()
  end, "VimQuest: pause / resume")
  map("<F3>", function()
    cheatsheet.toggle()
  end, "VimQuest: cheatsheet of everything you have learned")
  map("<F4>", function()
    questlog.toggle()
  end, "VimQuest: quest log")
  map("<F5>", function()
    skilltree.toggle()
  end, "VimQuest: skill tree")
  -- m / ' / ` become shrine binding and fast travel.
  travel.attach(buf)
end

---@param zone_id string|nil
---@param opts table|nil { at = {row, col} to override the spawn, brief = false to skip the briefing }
function M.start(zone_id, opts)
  if state.running then
    vim.notify("VimQuest is already running", vim.log.levels.WARN)
    return
  end
  opts = opts or {}

  local zone = zones.load(zone_id or config.options.start_zone)
  if opts.at then
    zone.spawn = { row = opts.at.row, col = opts.at.col }
  end

  state.reset()
  state.player = state.new_player(config.options)
  -- Skills, xp and cleared zones carry over between runs; everything else is
  -- fresh. apply_to_player turns those levels back into max health.
  save.load_into_state()
  skills.apply_to_player()

  render.open(zone)
  for _, spec in ipairs(zone.entities) do
    entity.spawn(spec)
  end

  collision.attach()
  input.attach()
  set_keymaps(state.buf)

  state.running = true
  -- Unlocks the buffer and paints the text-mobs, but only in a combat zone.
  combat.attach(zone)
  quests.on_zone_entered(zone.id)

  -- Opening briefing: the whole zone's premise and controls, read at your pace.
  -- Arriving by fast travel skips it; you have been here before.
  local brief = zone.brief or { zone.intro or "" }
  state.say(brief)
  if opts.brief ~= false then
    dialogue.show(brief, {
      title = zone.name,
      footer = "<CR> begin   -   <F1> journal   -   <F3> cheatsheet   -   <F4> quests",
    })
  end

  tick.start()
  render.draw()
  hud.render()
end

---Move between places without ending the run: a doorway, or a shrine mark.
---Progress is written before the teardown, so nothing is lost in transit.
---@param zone_id string
---@param at table|nil { row, col }
---@param text string|nil a line to show on arrival
function M.travel(zone_id, at, text)
  if not state.running or not zone_id then
    return
  end
  local carried = vim.deepcopy(state.journal)
  M.quit({ quiet = true })
  vim.schedule(function()
    -- Arriving at a shrine you already bound needs no briefing; walking
    -- through a door into a new zone does.
    M.start(zone_id, { at = at, brief = at == nil })
    if not state.running then
      return
    end
    -- The journal is a record of the session, not of one zone.
    vim.list_extend(carried, state.journal)
    state.journal = carried
    if text then
      state.say(text)
    end
    hud.render()
  end)
end

---Zone cleared. Show the summary, then leave or replay.
---@param ex table exit descriptor from the zone data
function M.complete(ex)
  if not state.running or state.dialog_open then
    return
  end

  local p = state.player
  local seconds = math.floor((state.tick_count * config.options.tick_ms) / 1000)
  local zone_id = state.zone.id
  local zone_name = state.zone.name
  local next_id = ex.to

  state.zones_cleared[zone_id] = true
  quests.on_zone_cleared(zone_id)
  if config.options.save.autosave then
    save.write()
  end

  local alive, total = combat.census()
  local lines = {
    ex.text or "You step through the portal. The Buffer quiets behind you.",
    "",
    ("Zone      %s"):format(zone_name),
    ("Time      %dm %02ds"):format(math.floor(seconds / 60), seconds % 60),
    ("Keys      %d pressed"):format(#state.keylog),
    ("Health    %d/%d"):format(p.hp, p.max_hp),
  }
  if total > 0 then
    table.insert(lines, ("Slain     %d of %d   (best combo x%d)"):format(total - alive, total, state.stats.best_combo))
    table.insert(lines, ("Misses    %d strikes went wide"):format(state.stats.misses))
  end
  table.insert(lines, ("Journal   %d entries  (<F1> in game to re-read)"):format(#state.journal))
  table.insert(lines, "")
  table.insert(lines, "Skills")
  vim.list_extend(lines, skills.report())
  table.insert(lines, "")
  table.insert(lines, "Progress saved. Levels and xp carry into your next run.")

  local footer = "<CR> leave   -   r replay this zone"
  if next_id then
    footer = "<CR> leave   -   r replay   -   n on to the next zone"
  end

  local go_to = nil
  local pan
  pan = panel.open({
    lines = lines,
    title = "ZONE CLEARED - " .. zone_name,
    footer = footer,
    close_keys = { "<CR>", "<Esc>", "q" },
    on_close = function()
      M.quit()
      if go_to then
        vim.schedule(function()
          M.start(go_to)
        end)
      end
    end,
  })
  local jump = function(id)
    return function()
      go_to = id
      pan.close()
    end
  end
  vim.keymap.set("n", "r", jump(zone_id), { buffer = pan.buf, nowait = true, silent = true })
  if next_id then
    vim.keymap.set("n", "n", jump(next_id), { buffer = pan.buf, nowait = true, silent = true })
  end
end

---@param opts table|nil { quiet = true } to skip the farewell notification
function M.quit(opts)
  if not state.running then
    return
  end
  if config.options.save.autosave then
    save.write()
  end
  dialogue.close()
  journal.close()
  cheatsheet.close()
  questlog.close()
  skilltree.close()
  converse.close()
  board.close()
  state.running = false
  tick.stop()
  input.detach()
  collision.detach()
  combat.detach()
  render.close()
  state.reset()
  if not (opts and opts.quiet) then
    vim.notify("VimQuest: the Buffer releases you.", vim.log.levels.INFO)
  end
end

function M.toggle_pause()
  if not state.running then
    return
  end
  state.paused = not state.paused
  hud.render()
end

---Wipe saved progress. Destructive, so it asks first whenever there is a human
---at the other end.
function M.reset()
  -- Resetting mid-run is pointless: quitting would write the save straight back.
  if state.running then
    vim.notify("VimQuest: leave the world first (<Esc><Esc>), then reset.", vim.log.levels.WARN)
    return
  end
  if not save.exists() then
    vim.notify("VimQuest: no saved progress to reset.", vim.log.levels.INFO)
    return
  end
  if #vim.api.nvim_list_uis() > 0 then
    local answer = vim.fn.confirm("Delete all VimQuest progress (skills, xp, zones cleared)?", "&No\n&Yes", 1)
    if answer ~= 2 then
      vim.notify("VimQuest: progress kept.", vim.log.levels.INFO)
      return
    end
  end
  if save.delete() then
    vim.notify("VimQuest: progress erased. The Buffer forgets you.", vim.log.levels.INFO)
  else
    vim.notify("VimQuest: could not delete " .. save.path(), vim.log.levels.ERROR)
  end
end

---Entry point used by the :VimQuest command.
---@param args string[]
function M.command(args)
  local sub = args[1] or "start"
  if sub == "start" then
    M.start(args[2])
  elseif sub == "zone" then
    if state.running then
      M.quit()
    end
    M.start(args[2])
  elseif sub == "quit" or sub == "stop" then
    M.quit()
  elseif sub == "pause" then
    M.toggle_pause()
  elseif sub == "reset" then
    M.reset()
  else
    vim.notify("VimQuest: unknown subcommand '" .. sub .. "'", vim.log.levels.ERROR)
  end
end

return M
