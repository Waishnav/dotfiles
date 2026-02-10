-- Harpoon for quick file navigation (ThePrimeagen style)
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    local map = vim.keymap.set

    -- Add file to harpoon
    map("n", "<leader>a", function()
      harpoon:list():add()
    end, { desc = "Harpoon add file" })

    -- Toggle harpoon menu
    map("n", "<leader>h", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Harpoon menu" })

    -- Quick navigation to harpooned files (Ctrl + number keys on home row)
    map("n", "<C-a>", function() harpoon:list():select(1) end, { desc = "Harpoon file 1" })
    map("n", "<C-s>", function() harpoon:list():select(2) end, { desc = "Harpoon file 2" })
    -- Note: <C-d> is used for scroll down, so we skip it
    map("n", "<C-f>", function() harpoon:list():select(3) end, { desc = "Harpoon file 3" })
    map("n", "<C-g>", function() harpoon:list():select(4) end, { desc = "Harpoon file 4" })
  end,
}
