-- Theme auto-detection: cursor-dark for dark mode, kanagawa-lotus for light mode

local function get_system_theme()
  local handle = io.popen(
    'gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "prefer-light"'
  )
  if not handle then
    return "dark"
  end
  local result = handle:read("*a")
  handle:close()
  -- prefer-dark or Adwaita-dark or any gtk theme ending in -dark
  if result:find("prefer%-dark") or result:find("%-dark") then
    return "dark"
  end
  return "light"
end

-- Track last applied theme to avoid redundant redraws
local last_theme = nil

--- Apply the correct colorscheme based on the system theme.
--- Can be called externally via nvim --remote-send or mapped to a key.
function _G.SyncSystemTheme()
  local theme = get_system_theme()
  if theme == last_theme then
    return
  end
  last_theme = theme

  -- Clear highlights before switching
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.o.background = theme

  if theme == "dark" then
    pcall(function()
      require("cursor-dark").setup({
        style = "dark",
        transparent = true,
        dashboard = true,
      })
      vim.cmd.colorscheme("cursor-dark")
    end)
  else
    pcall(function()
      require("kanagawa").setup({
        theme = "lotus",
        transparent = true,
      })
      vim.cmd.colorscheme("kanagawa")
    end)
  end

  vim.cmd("redraw!")
end

-- Auto-sync when nvim regains focus (handles system theme toggle while nvim is running)
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    vim.schedule(_G.SyncSystemTheme)
  end,
})

-- Watch the omarchy alacritty theme file for live changes
local watcher_path = vim.fn.expand("~/.config/omarchy/current/theme/alacritty.toml")
if vim.uv.fs_stat(watcher_path) then
  local watcher = vim.uv.new_fs_event()
  if watcher then
    watcher:start(watcher_path, {}, vim.schedule_wrap(function()
      _G.SyncSystemTheme()
    end))
  end
end

-- Determine which theme to use at startup
local is_dark = get_system_theme() == "dark"
-- Set background early so kanagawa can auto-detect lotus variant in light mode
vim.o.background = is_dark and "dark" or "light"

return {
  {
    "ydkulks/cursor-dark.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cursor-dark").setup({
        style = "dark",
        transparent = true,
        dashboard = true,
      })
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 999,
    opts = {
      transparent = true,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = is_dark and "cursor-dark" or "kanagawa",
    },
  },
}
