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
local tick = require("vimquest.engine.tick")
local hud = require("vimquest.ui.hud")
local panel = require("vimquest.ui.panel")
local dialogue = require("vimquest.ui.dialogue")
local journal = require("vimquest.ui.journal")

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
end

---@param zone_id string|nil
function M.start(zone_id)
  if state.running then
    vim.notify("VimQuest is already running", vim.log.levels.WARN)
    return
  end

  local zone = zones.load(zone_id or config.options.start_zone)

  state.reset()
  state.player = state.new_player(config.options)

  render.open(zone)
  for _, spec in ipairs(zone.entities) do
    entity.spawn(spec)
  end

  collision.attach()
  input.attach()
  set_keymaps(state.buf)

  state.running = true

  -- Opening briefing: the whole zone's premise and controls, read at your pace.
  local brief = zone.brief or { zone.intro or "" }
  state.say(brief)
  dialogue.show(brief, {
    title = zone.name,
    footer = "<CR> begin   -   <F1> journal anytime   -   <F2> pause",
  })

  tick.start()
  render.draw()
  hud.render()
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
  local lines = {
    ex.text or "You step through the portal. The Buffer quiets behind you.",
    "",
    ("Zone      %s"):format(state.zone.name),
    ("Time      %dm %02ds"):format(math.floor(seconds / 60), seconds % 60),
    ("Keys      %d pressed"):format(#state.keylog),
    ("Health    %d/%d"):format(p.hp, p.max_hp),
    ("Journal   %d entries  (<F1> in game to re-read)"):format(#state.journal),
    "",
    "Next: operator combat arrives with The Rotwood - x, dw, di\", ca(",
    "will become attacks, and the map itself becomes editable.",
  }

  local replay = false
  local pan
  pan = panel.open({
    lines = lines,
    title = "ZONE CLEARED - " .. state.zone.name,
    footer = "<CR> leave   -   r replay this zone",
    close_keys = { "<CR>", "<Esc>", "q" },
    on_close = function()
      M.quit()
      if replay then
        vim.schedule(function()
          M.start(zone_id)
        end)
      end
    end,
  })
  vim.keymap.set("n", "r", function()
    replay = true
    pan.close()
  end, { buffer = pan.buf, nowait = true, silent = true })
end

function M.quit()
  if not state.running then
    return
  end
  dialogue.close()
  journal.close()
  state.running = false
  tick.stop()
  input.detach()
  collision.detach()
  render.close()
  state.reset()
  vim.notify("VimQuest: the Buffer releases you.", vim.log.levels.INFO)
end

function M.toggle_pause()
  if not state.running then
    return
  end
  state.paused = not state.paused
  hud.render()
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
  else
    vim.notify("VimQuest: unknown subcommand '" .. sub .. "'", vim.log.levels.ERROR)
  end
end

return M
