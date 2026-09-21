-- https://github.com/nvim-treesitter/nvim-treesitter
-- https://www.lazyvim.org/plugins/treesitter

return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local treesitter_config = require("nvim-treesitter.configs")
			treesitter_config.setup({
				-- Automatically install missing parsers when entering buffer
				-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
				-- auto_install = true,

				ensure_installed = {
					"astro",
					"bash",
					"c",
					"css",
					"csv",
					"dockerfile",
					"go",
					"gnuplot",
					"graphql",
					"hcl",
					"html",
					"javascript",
					"json",
					"lua",
					"php",
					"python",
					"sql",
					"typescript",
					"rust",
					"yaml",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
}
