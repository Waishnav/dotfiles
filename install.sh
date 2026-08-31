#!/bin/bash
# Dotfiles installer using GNU Stow
# Usage: ./install.sh [module...]
# If no modules specified, installs all

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES=(hypr waybar alacritty tmux nvim scripts zsh fish libinput-gestures)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

# Check for stow
if ! command -v stow &> /dev/null; then
    error "GNU Stow is required. Install with: sudo pacman -S stow"
    exit 1
fi

# Determine which modules to install
if [[ $# -gt 0 ]]; then
    SELECTED=("$@")
else
    SELECTED=("${MODULES[@]}")
fi

cd "$DOTFILES_DIR"

for module in "${SELECTED[@]}"; do
    if [[ -d "$module" ]]; then
        log "Stowing $module..."
        stow -v --target="$HOME" "$module" 2>&1 | grep -v "^BUG" || true
    else
        warn "Module '$module' not found, skipping"
    fi
done

log "Done! You may need to reload your configs:"
echo "  - Hyprland: hyprctl reload"
echo "  - Waybar: pkill -SIGUSR2 waybar"
echo "  - Zsh: source ~/.zshrc"
echo "  - Tmux: tmux source ~/.config/tmux/tmux.conf"
echo "  - Gestures: libinput-gestures-setup restart"
