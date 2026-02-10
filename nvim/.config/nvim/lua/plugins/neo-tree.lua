-- Neo-tree config: show hidden files by default
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
}
