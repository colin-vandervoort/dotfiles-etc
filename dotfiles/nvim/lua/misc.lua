vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.opt.number = true
vim.opt.relativenumber = true

vim.g.mapleader = " "

-- Set filetypes for certain files without extensions
local shell_files = {
  "~/.bashrc",
  "~/.bash_aliases",
  "~/.bash_profile",
  "~/.profile",
  "~/.zshrc",
}
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = shell_files,
  callback = function()
    vim.bo.filetype = "sh"
  end,
})
