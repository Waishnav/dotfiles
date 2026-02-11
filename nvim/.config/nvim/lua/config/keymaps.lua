-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Move selected lines up/down in visual mode (ThePrimeagen style)
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Keep cursor in place when joining lines
map("n", "J", "mzJ`z")

-- System clipboard shortcuts
map("n", "<leader>P", [["+P]], { desc = "Paste from clipboard (before)" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map({ "n", "v" }, "<leader>p", [["+p]], { desc = "Paste from clipboard" })

-- Delete without yanking
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yank" })

-- Escape with Ctrl+c in insert mode
map("i", "<C-c>", "<Esc>")

-- Disable macro recording (q is annoying)
map("n", "q", "<nop>")

-- Format with conform (falls back to LSP)
map("n", "<leader>f", function()
  require("conform").format({
    lsp_fallback = true,
    timeout_ms = 500,
  })
end, { desc = "Format file" })

-- Quickfix navigation
map("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
map("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
map("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next loclist" })
map("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Prev loclist" })

-- Make file executable
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make executable" })

-- Source current file
map("n", "<leader><leader>", function()
  vim.cmd("so")
end, { desc = "Source file" })

-- Close buffer
map("n", "<leader>c", "<cmd>bd<CR>", { desc = "Close buffer" })

-- Splits
map("n", "<leader>sh", ":split<CR>", { desc = "Horizontal split" })
map("n", "<leader>sv", ":vsplit<CR>", { desc = "Vertical split" })

-- Buffer navigation with Alt+[ and Alt+]
map("n", "<A-[>", "<cmd>bp<CR>", { desc = "Previous buffer" })
map("n", "<A-]>", "<cmd>bn<CR>", { desc = "Next buffer" })

-- Window navigation with Alt+hjkl
map("n", "<A-h>", "<C-w>h", { desc = "Window left" })
map("n", "<A-l>", "<C-w>l", { desc = "Window right" })
map("n", "<A-k>", "<C-w>k", { desc = "Window up" })
map("n", "<A-j>", "<C-w>j", { desc = "Window down" })

-- Search selection in visual mode
map("x", "<leader>f", "y/<C-R>=escape(@\", '/')<CR><CR>", { noremap = false, silent = false, desc = "Search selection" })

-- Global live search (live_grep) using snacks picker
map("n", "<leader>ls", function()
  Snacks.picker.grep({ hidden = true })
end, { desc = "Global live search" })

-- Find files (from old config - <leader>sf)
map("n", "<leader>sf", function()
  Snacks.picker.files({ hidden = true })
end, { desc = "Find files" })

-- Toggle indent between 2 and 4 spaces
map("n", "<leader>ti", function()
  if vim.opt.shiftwidth:get() == 2 then
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.softtabstop = 4
    print("Indent: 4 spaces")
  else
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.softtabstop = 2
    print("Indent: 2 spaces")
  end
end, { desc = "Toggle indent 2/4" })

-- File explorer (netrw style, but LazyVim uses neo-tree)
map("n", "<leader>vp", vim.cmd.Ex, { desc = "Open netrw" })


