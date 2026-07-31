if vim.g.loaded_codediff then
  return
end
vim.g.loaded_codediff = true

vim.api.nvim_create_user_command("CodeDiff", function(opts)
  local args = opts.fargs
  if #args ~= 2 then
    vim.notify("CodeDiff needs exactly two file arguments: :CodeDiff {before} {after}", vim.log.levels.ERROR)
    return
  end
  require("codediff").open_diff(args[1], args[2])
end, {
  nargs = "+",
  complete = "file",
  desc = "Diff two files with codediff",
})

vim.api.nvim_create_user_command("CodeDiffThis", function()
  require("codediff").diff_this()
end, {
  desc = "Diff the current buffer's unsaved changes against the on-disk file with codediff",
})
