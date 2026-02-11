-- Incremental selection using treesitter (replaces removed nvim-treesitter module)
-- Uses <C-@> because terminals (Alacritty, etc) send Ctrl+Space as NUL (^@), which Neovim reads as <C-@>
return {
  "daliusd/incr.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("incr").setup({
      incr_key = "<C-@>",
      decr_key = "<c-backspace>",
    })
  end,
}
