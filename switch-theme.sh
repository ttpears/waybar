#!/bin/bash
# Waybar Theme Switcher

WAYBAR_DIR="$HOME/.config/waybar"

case "$1" in
  nordic)
    ln -sf "$WAYBAR_DIR/style-nordic.css" "$WAYBAR_DIR/style.css"
    echo "Switched to Nordic theme"
    ;;
  synthwave)
    ln -sf "$WAYBAR_DIR/style-synthwave.css" "$WAYBAR_DIR/style.css"
    echo "Switched to Synthwave theme"
    ;;
  tokyonight)
    ln -sf "$WAYBAR_DIR/style-tokyonight.css" "$WAYBAR_DIR/style.css"
    echo "Switched to Tokyo Night theme"
    ;;
  catppuccin)
    ln -sf "$WAYBAR_DIR/style-catppuccin.css" "$WAYBAR_DIR/style.css"
    echo "Switched to Catppuccin Mocha theme"
    ;;
  cyberpunk)
    ln -sf "$WAYBAR_DIR/style-cyberpunk.css" "$WAYBAR_DIR/style.css"
    echo "Switched to Cyberpunk theme"
    ;;
  *)
    echo "Usage: $0 {nordic|synthwave|tokyonight|catppuccin|cyberpunk}"
    echo ""
    echo "Available themes:"
    echo "  nordic      - Cool Nordic/Nord colors"
    echo "  synthwave   - Hot pink, cyan, purple neon (Outrun)"
    echo "  tokyonight  - Deep blue with electric accents"
    echo "  catppuccin  - Rich pastels on mocha base"
    echo "  cyberpunk   - Matrix green with neon cyan"
    exit 1
    ;;
esac

# Reload waybar
pkill waybar
waybar &
