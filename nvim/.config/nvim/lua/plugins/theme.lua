-- Cursor Dark theme
return {
  {
    "ydkulks/cursor-dark.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cursor-dark").setup({
        style = "dark-midnight",
        transparent = true,
        dashboard = true,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "cursor-dark-midnight",
    },
  },
}
