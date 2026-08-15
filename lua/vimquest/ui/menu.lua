-- A panel you can choose from.
--
-- Conversations and the skill tree both need "some text, then a list you pick
-- from", so that lives here once rather than twice. Built on ui/panel.lua, so
-- it freezes the world like every other panel: choosing is never timed.
--
-- Selection is j/k plus <CR>, which is deliberate - the menu keys are the same
-- keys the game is teaching. Number keys work too, for speed.

local panel = require("vimquest.ui.panel")

local M = {}

---@class VimQuestMenuItem
---@field label string
---@field hint string|nil right-hand column, e.g. a cost or a status
---@field enabled boolean|nil false renders it dimmed and refuses selection
---@field value any passed back to on_select

---@class VimQuestMenuOpts
---@field header string[]|nil text above the choices
---@field items VimQuestMenuItem[]
---@field title string|nil
---@field footer string|nil
---@field on_select fun(item: VimQuestMenuItem, menu: table)|nil
---@field on_close fun()|nil

---@param opts VimQuestMenuOpts
---@return table menu { close, set, panel }
function M.open(opts)
  local menu = { index = 1 }
  local current = opts

  local function body()
    local lines = {}
    vim.list_extend(lines, current.header or {})
    if #lines > 0 then
      table.insert(lines, "")
    end
    for i, item in ipairs(current.items or {}) do
      local marker = i == menu.index and ">" or " "
      local label = ("%s %d. %s"):format(marker, i, item.label)
      if item.hint then
        label = label .. "   -   " .. item.hint
      end
      if item.enabled == false then
        label = label .. "   [locked]"
      end
      table.insert(lines, label)
    end
    if #(current.items or {}) == 0 then
      table.insert(lines, "  (nothing here)")
    end
    return lines
  end

  local function redraw()
    if menu.panel then
      menu.panel.render(body())
    end
  end

  local function move(delta)
    local n = #(current.items or {})
    if n == 0 then
      return
    end
    menu.index = ((menu.index - 1 + delta) % n) + 1
    redraw()
  end

  local function choose(i)
    local item = (current.items or {})[i or menu.index]
    if not item or item.enabled == false then
      return
    end
    menu.index = i or menu.index
    if current.on_select then
      current.on_select(item, menu)
    end
  end

  ---Replace the menu's contents in place - a conversation walking to the next
  ---node, or the skill tree after a perk is bought.
  ---@param next_opts VimQuestMenuOpts
  function menu.set(next_opts)
    current = vim.tbl_extend("force", current, next_opts)
    menu.index = 1
    redraw()
    if menu.panel and next_opts.footer then
      menu.panel.set_footer(next_opts.footer)
    end
  end

  local keys = {
    ["j"] = function()
      move(1)
    end,
    ["k"] = function()
      move(-1)
    end,
    ["<Down>"] = function()
      move(1)
    end,
    ["<Up>"] = function()
      move(-1)
    end,
    ["<CR>"] = function()
      choose()
    end,
  }
  for i = 1, 9 do
    keys[tostring(i)] = function()
      choose(i)
    end
  end

  menu.panel = panel.open({
    lines = body(),
    title = opts.title,
    footer = opts.footer or "j / k choose   -   <CR> select   -   <Esc> leave",
    close_keys = { "<Esc>", "q" },
    keys = keys,
    on_close = function()
      -- Read through `current`, not `opts`: a menu that has been re-set with
      -- menu.set() should run the handler it has now, not its first one.
      if current.on_close then
        current.on_close()
      end
    end,
  })

  function menu.close()
    menu.panel.close()
  end

  return menu
end

return M
