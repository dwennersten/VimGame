-- Command registration. Kept tiny so the plugin costs nothing at startup:
-- the game modules are only required when :VimQuest is actually run.

if vim.g.loaded_vimquest then
  return
end
vim.g.loaded_vimquest = true

vim.api.nvim_create_user_command("VimQuest", function(opts)
  require("vimquest").command(opts.fargs)
end, {
  nargs = "*",
  desc = "VimQuest: start / quit / pause the game",
  complete = function(_, line)
    local args = vim.split(vim.trim(line), "%s+")
    if #args <= 2 then
      return { "start", "quit", "pause", "zone" }
    end
    if args[2] == "zone" or args[2] == "start" then
      return { "00_awakening" }
    end
    return {}
  end,
})
