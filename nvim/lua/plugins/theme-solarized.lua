return {
  {
    "shaunsingh/solarized.nvim",
    name = "solarized",
    priority = 1000,
    config = function()
      vim.g.solarized_italic_comments = true
      vim.g.solarized_italic_keywords = true
      vim.g.solarized_italic_functions = false
      vim.g.solarized_italic_variables = false
      vim.g.solarized_contrast = true
      vim.g.solarized_borders = false
      vim.g.solarized_disable_background = false

      require("solarized").set()
    end
  }
}
