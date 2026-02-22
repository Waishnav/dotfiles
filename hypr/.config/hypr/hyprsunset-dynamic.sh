#!/bin/bash
# Save as ~/.config/hypr/hyprsunset-dynamic.sh

# Get the currently focused monitor
FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

# Set temperature based on monitor
case "$FOCUSED_MONITOR" in
    "eDP-1")  # laptop screen - warmer
        hyprctl hyprsunset temperature 4000
        ;;
    "DP-1")   # external monitor - cooler
        hyprctl hyprsunset temperature 5500
        ;;
    *)        # default
        hyprctl hyprsunset temperature 5000
        ;;
esac
