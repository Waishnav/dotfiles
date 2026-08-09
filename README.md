# Dotfiles

My Arch Linux + Hyprland configuration with synchronized dual-monitor workspaces.

## Features

- **Synchronized workspaces**: Both monitors switch together (KDE-style virtual desktops)
- **Smart monitor handling**: Windows migrate automatically when external monitor disconnects
- **Touchpad gestures**: 3-finger swipe to switch workspaces
- **Cursor preservation**: Workspace switching doesn't move cursor

## Structure

```
dotfiles/
├── hypr/           # Hyprland config
├── waybar/         # Waybar config  
├── alacritty/      # Alacritty terminal config
├── tmux/           # Tmux config
├── scripts/        # Custom scripts (hypr-*, tmux-sessionizer)
├── zsh/            # Zsh config
├── git/            # Git config
└── libinput-gestures/  # Touchpad gestures
```

## Dependencies

```bash
# Core
sudo pacman -S hyprland waybar zsh stow alacritty tmux fzf

# For gestures
yay -S libinput-gestures
sudo gpasswd -a $USER input

# For monitor event handling
sudo pacman -S socat jq
```

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Or install specific modules:

```bash
./install.sh hypr waybar scripts
```

## Workspace Layout

| Key | Laptop (eDP-1) | External (HDMI-A-1) |
|-----|----------------|---------------------|
| Super+1 | WS 1 | WS 11 |
| Super+2 | WS 2 | WS 12 |
| Super+3 | WS 3 | WS 13 |
| Super+8 | WS 4 | WS 14 |
| Super+9 | WS 5 | WS 15 |
| Super+0 | WS 6 | WS 16 |

## Custom Scripts

- `hypr-switch-workspace` - Switch synchronized workspace pairs
- `hypr-move-to-workspace` - Move window (context-aware based on monitor)
- `hypr-event-listener` - Handle monitor connect/disconnect events
- `hypr-gesture-workspace` - Handle touchpad gesture workspace switching
- `tmux-sessionizer` - Fuzzy find and attach to project tmux sessions

## Notes

- Requires [Omarchy](https://github.com/omarchy/omarchy) base config
- External monitor config assumes HDMI-A-1 above eDP-1
