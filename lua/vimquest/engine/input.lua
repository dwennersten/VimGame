-- Keystroke recorder and stamina charging.
--
-- Every key you press while the game is running is logged with a timestamp.
-- Combat reads the tail of this log to decide which command earned a kill, and
-- later segments read it for keystroke-golf scoring, ghost replays and adaptive
-- weakness detection, so the format is deliberately simple and stable.
--
-- Only *typed* keys are recorded. vim.on_key also reports the keys Neovim
-- generates internally while executing a command - pressing x really feeds
-- "x", "d", "l" - and counting those would both overcharge stamina and make the
-- keylog describe vim's internals instead of the player's fingers.

local state = require("vimquest.state")
local config = require("vimquest.config")

local M = {}

M.ns = vim.api.nvim_create_namespace("vimquest_input")
local attached = false

---@param key string raw key bytes as delivered by vim.on_key
local function charge_stamina(key)
  local p = state.player
  if not p then
    return
  end
  local costs = config.options.stamina_cost
  local cost = costs[key] or costs.default
  p.stamina = math.max(0, p.stamina - cost)
end

function M.attach()
  if attached then
    return
  end
  attached = true
  vim.on_key(function(key, typed)
    if not state.running or state.paused then
      return
    end
    -- Only count input aimed at the game buffer.
    if vim.api.nvim_get_current_buf() ~= state.buf then
      return
    end
    local k = typed or ""
    if k == "" then
      return
    end
    charge_stamina(k)
    if config.options.log_keys then
      table.insert(state.keylog, { key = k, at = vim.uv.now() })
      if #state.keylog > config.options.max_keylog then
        table.remove(state.keylog, 1)
      end
    end
  end, M.ns)
end

function M.detach()
  if not attached then
    return
  end
  attached = false
  vim.on_key(nil, M.ns)
end

return M
