-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Block cursor in all modes
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr-o:block"

-- Tabs and indentation (default 4, but 2 for web files via autocmd)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Show whitespace characters
vim.opt.list = true
vim.opt.listchars:append({ tab = "• ", trail = "·", nbsp = "␣" })

-- No line wrap
vim.opt.wrap = false

-- Persistent undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Search
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Appearance
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"

-- Performance
vim.opt.updatetime = 250

-- Include @ in filenames
vim.opt.isfname:append("@-@")

-- Netrw settings
vim.g.netrw_bufsettings = "noma nomod nu rnu nobl nowrap ro"

-- Filetype-specific indentation (2 spaces for web files)
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "javascript", "typescript", "javascriptreact", "typescriptreact",
    "html", "css", "scss", "json", "yaml", "lua", "vim", "markdown"
  },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})
