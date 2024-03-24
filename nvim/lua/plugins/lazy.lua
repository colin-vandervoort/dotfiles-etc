local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  'tpope/vim-dadbod',
  'kristijanhusak/vim-dadbod-ui',
  'kristijanhusak/vim-dadbod-completion',
  -- Database
  {
    "tpope/vim-dadbod",
    opt = true,
    requires = {
      'kristijanhusak/vim-dadbod-ui',
      'kristijanhusak/vim-dadbod-completion',
    },
    config = function()
      require("config.dadbod").setup()
    end,
  },
  { "shaunsingh/solarized.nvim", name = "solarized", priority = 1000 },
  -- { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    'numToStr/Comment.nvim',
    opts = {
      -- add any options here
    },
    lazy = false,
  },
  {
    "nvim-telescope/telescope.nvim", tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  }
}
local opts = {}

require("lazy").setup(plugins, opts)

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<C-p>", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})

local treesitter_config = require("nvim-treesitter.configs")
treesitter_config.setup({
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
    "yaml"
  },
  highlight = { enable = true },
  indent = { enable = true }, 
})

-- require("catppuccin").setup()
-- vim.cmd.colorscheme "catppuccin"

vim.g.solarized_italic_comments = true
vim.g.solarized_italic_keywords = true
vim.g.solarized_italic_functions = false
vim.g.solarized_italic_variables = false
vim.g.solarized_contrast = true
vim.g.solarized_borders = false
vim.g.solarized_disable_background = false
require("solarized").set()
