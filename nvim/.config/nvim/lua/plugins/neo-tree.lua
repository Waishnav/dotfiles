-- Neo-tree config: disabled auto-open, manual toggle only
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,         -- Show hidden files
        hide_dotfiles = false,  -- Don't hide dotfiles
        hide_gitignored = false, -- Show gitignored files too
      },
    },
  },
  -- Disable auto-open on startup by removing LazyVim's autocmd
  init = function()
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("disable_neotree_autoopen", { clear = true }),
      callback = function()
        -- Remove LazyVim's neo-tree auto-open autocmd
        local ok, lazyvim_augroup = pcall(vim.api.nvim_get_augroup, "lazyvim_neotree")
        if ok and lazyvim_augroup then
          vim.api.nvim_clear_autocmds({ group = "lazyvim_neotree" })
        end
      end,
      once = true,
    })
  end,
}
