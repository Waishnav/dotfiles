#!/usr/bin/env bash

show_toggle_menu() {
  case $(menu "Toggle" "󱄄  Screensaver\n󰔎  Nightlight\n󱫖  Idle Lock\n󰍜  Top Bar\n󰌵  Appearance (Light/Dark)") in
  *Screensaver*) omarchy-toggle-screensaver ;;
  *Nightlight*) omarchy-toggle-nightlight ;;
  *Idle*) omarchy-toggle-idle ;;
  *Bar*) omarchy-toggle-waybar ;;
  *Appearance*) ~/.local/bin/toggle-system-theme ;;
  *) show_trigger_menu ;;
  esac
}
