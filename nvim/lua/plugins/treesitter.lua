return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
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
    end
  }
}
