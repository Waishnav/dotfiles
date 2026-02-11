return {
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = function()
      require("Comment").setup()
    end,
    keys = {
      -- Ctrl+/ for commenting (like your old config)
      {
        "<c-_>",
        function()
          return vim.v.count == 0 and "<Plug>(comment_toggle_linewise_current)"
            or "<Plug>(comment_toggle_linewise_count)"
        end,
        expr = true,
        desc = "Toggle comment",
        mode = "n",
      },
      { "<c-_>", "<Plug>(comment_toggle_linewise_visual)", desc = "Toggle comment", mode = "x" },
      { "<c-_>", "<Esc><Plug>(comment_toggle_linewise_current)i", desc = "Toggle comment", mode = "i" },
      -- Also keep leader+/ for commenting
      { "<leader>/", "gcc", remap = true, desc = "Toggle comment", mode = "n" },
      { "<leader>/", "gc", remap = true, desc = "Toggle comment", mode = "x" },
    },
  },
}
