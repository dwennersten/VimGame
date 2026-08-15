-- Standalone play mode.
--
-- Launched by scripts/play.ps1 (or play.sh) as:
--     NVIM_APPNAME=vimquest nvim -u <repo>/init.lua
--
-- NVIM_APPNAME points Neovim's config/data paths at a "vimquest" profile, so
-- this can never read or modify a real ~/.config/nvim (or ~/AppData/Local/nvim)
-- setup. This file is also the readable example distro: options, keymaps and
-- plugin wiring, all in one place.

local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.runtimepath:prepend(repo)

-- ---------------------------------------------------------------- options ---
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = false
vim.opt.showmode = false
vim.opt.laststatus = 2
vim.opt.cmdheight = 1
vim.opt.updatetime = 100
vim.opt.timeoutlen = 400
vim.opt.mouse = ""
vim.opt.swapfile = false
vim.opt.shortmess:append("I")
vim.opt.fillchars:append({ eob = " " })

vim.cmd("colorscheme habamax")
vim.api.nvim_set_hl(0, "Normal", { bg = "#12111a", fg = "#cfc9dd" })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1c1a28" })
vim.api.nvim_set_hl(0, "Cursor", { fg = "#12111a", bg = "#f4d06f" })

-- ----------------------------------------------------------------- game ----
require("vimquest").setup({})

-- Splash screen: a scratch buffer with the pitch and one instruction.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "",
      "   V I M Q U E S T",
      "   The Corrupted Buffer",
      "",
      "   You are the cursor. The text is the world.",
      "",
      "   :VimQuest        enter the world",
      "   <Esc><Esc>       leave the world",
      "   <F2>             pause",
      "   :qa              quit Neovim",
      "",
    })
    vim.bo[buf].modifiable = false
    vim.api.nvim_win_set_buf(0, buf)
  end,
})
