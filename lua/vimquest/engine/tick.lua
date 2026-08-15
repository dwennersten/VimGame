-- The world clock.
--
-- A libuv timer drives real-time behaviour. Timer callbacks run off the main
-- loop, so every callback body is wrapped in vim.schedule before touching the
-- Neovim API. Focus loss auto-pauses: a real-time game inside your editor must
-- never keep hitting you while you are elsewhere.

local state = require("vimquest.state")
local config = require("vimquest.config")
local grid = require("vimquest.engine.grid")
local entity = require("vimquest.engine.entity")
local render = require("vimquest.engine.render")
local hud = require("vimquest.ui.hud")

local M = {}

M.timer = nil
M.group = vim.api.nvim_create_augroup("VimQuestTick", { clear = true })

---Fire any trigger on this cell. The world freezes and the text waits in a
---panel until dismissed, so nothing has to be read against the clock.
---@param zone table
---@param row integer
---@param col integer
local function fire_triggers(zone, row, col)
  for _, t in ipairs(zone.triggers or {}) do
    if t.row == row and t.col == col and not t._fired then
      t._fired = true
      state.say(t.text)
      if t.quiet then
        return
      end
      local body = type(t.text) == "table" and vim.deepcopy(t.text) or { t.text }
      require("vimquest.ui.dialogue").show(body, { title = t.title })
      return
    end
  end
end

---@param zone table
---@param row integer
---@param col integer
---@return table|nil
local function exit_at(zone, row, col)
  for _, x in ipairs(zone.exits or {}) do
    if x.row == row and x.col == col then
      return x
    end
  end
  return nil
end

local function damage_player(amount, reason)
  local p = state.player
  p.hp = p.hp - amount
  if p.hp <= 0 then
    p.hp = p.max_hp
    p.stamina = p.max_stamina
    local spawn = state.zone.spawn or { row = 0, col = 0 }
    grid.set_cursor(state.win, spawn.row, spawn.col)
    require("vimquest.engine.collision").set_anchor(spawn.row, spawn.col)
    state.say("You fall. The Buffer reassembles you at the shrine.")
  else
    state.say(reason)
  end
end

local function step()
  if not state.running or state.paused or state.dialog_open then
    return
  end
  local win, buf = state.win, state.buf
  if not win or not vim.api.nvim_win_is_valid(win) then
    require("vimquest").quit()
    return
  end
  -- Only run the world while the player is actually looking at it.
  if vim.api.nvim_get_current_buf() ~= buf then
    return
  end

  state.tick_count = state.tick_count + 1
  local zone = state.zone
  local prow, pcol = grid.cursor(win)

  fire_triggers(zone, prow, pcol)

  local ex = exit_at(zone, prow, pcol)
  if ex then
    require("vimquest").complete(ex)
    return
  end

  entity.update({ zone = zone, prow = prow, pcol = pcol })

  local now = vim.uv.now()
  local p = state.player

  -- Contact damage
  for _, e in ipairs(state.entities) do
    if e.hp > 0 and e.row == prow and e.col == pcol then
      if now - state.last_hit_ms >= config.options.damage.cooldown_ms then
        state.last_hit_ms = now
        damage_player(config.options.damage.contact, "The " .. e.name .. " tears at you!")
      end
      break
    end
  end

  -- Stamina: regen always, bleed HP while empty.
  if p.stamina <= 0 then
    if now - state.last_exhaust_ms >= 1000 then
      state.last_exhaust_ms = now
      damage_player(config.options.damage.exhaustion, "Exhausted. Stop mashing hjkl - use w, }, or a count.")
    end
  end
  p.stamina = math.min(p.max_stamina, p.stamina + config.options.player.stamina_regen)

  render.draw()
  hud.render()
end

function M.start()
  M.stop()
  M.timer = vim.uv.new_timer()
  M.timer:start(
    config.options.tick_ms,
    config.options.tick_ms,
    vim.schedule_wrap(function()
      local ok, err = pcall(step)
      if not ok then
        M.stop()
        vim.notify("VimQuest tick error: " .. tostring(err), vim.log.levels.ERROR)
      end
    end)
  )

  vim.api.nvim_create_autocmd({ "FocusLost" }, {
    group = M.group,
    callback = function()
      if state.running then
        state.paused = true
      end
    end,
  })
end

function M.stop()
  if M.timer then
    pcall(function()
      M.timer:stop()
      M.timer:close()
    end)
    M.timer = nil
  end
  pcall(vim.api.nvim_clear_autocmds, { group = M.group })
end

return M
