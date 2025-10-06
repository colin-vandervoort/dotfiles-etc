local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazy_path) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazy_path,
	})
end
vim.opt.rtp:prepend(lazy_path)

-- load the misc Lua module
require("misc")

-- load the lazy Lua module and pass the plugins module to the lazy setup function
-- this will merge together the plugin spec tables from each sub-module in the plugins module
-- see https://lazy.folke.io/usage/structuring
require("lazy").setup("plugins")
