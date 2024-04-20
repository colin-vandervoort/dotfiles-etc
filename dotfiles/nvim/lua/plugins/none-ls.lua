return {
  {
    "jay-babu/mason-null-ls.nvim",
    config = function()
      require("mason-null-ls").setup({
        ensure_installed = {
          -- diagnostics
          "hadolint",
          "markdownlint",

          -- formatters
          "black",
          "hclfmt",
          "isort",
          "prettier",
          -- "rubocop",
          "stylua",

          -- deprecated LSPs in none-ls plugin
          "beautysh",
          "eslint_d",
          "jq",
        },
      })
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "jay-babu/mason-null-ls.nvim",
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        debug = true,
        sources = {
          -- diagnostics
          null_ls.builtins.diagnostics.hadolint,
          null_ls.builtins.diagnostics.markdownlint,
          -- null_ls.builtins.diagnostics.rubocop,

          -- formatters
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.hclfmt,
          null_ls.builtins.formatting.isort,
          null_ls.builtins.formatting.prettier,

          -- none-ls-extras
          require("none-ls.code_actions.eslint_d"),
          require("none-ls.diagnostics.eslint_d"),
          require("none-ls.formatting.beautysh"),
          require("none-ls.formatting.jq"),
        }
      })

      vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
    end,
  },
}
