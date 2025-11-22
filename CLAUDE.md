# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Waybar configuration directory for a Sway window manager setup. Waybar is a highly customizable status bar for Wayland compositors. The configuration supports multi-monitor setups and includes multiple theme options.

## Architecture

### Theme System

The repository uses a symlink-based theme switching system:
- `style.css` is a symlink pointing to one of the theme files
- Theme files: `style-nordic.css`, `style-synthwave.css`, `style-tokyonight.css`, `style-catppuccin.css`, `style-cyberpunk.css`
- `switch-theme.sh` script handles theme switching and automatically reloads Waybar

### Configuration Structure

**config.jsonc**: Main Waybar configuration
- Uses `sway/workspaces` module (not `hyprland/workspaces` despite config containing unused hyprland sections)
- Configured for bottom position with 58px height (minimum required for styled modules)
- Multi-monitor aware: displays all workspaces across monitors
- Modules use Nerd Font icons (Iosevka Term Nerd Font)

**CSS Themes**: All theme files follow the same structure:
- Transparent backgrounds with rgba() for layered depth effect
- Border styling with subtle glows (box-shadow)
- Module padding: 6px vertical, 12px horizontal
- Module margins: 4px vertical, 6px horizontal
- Border radius: 8px for modules, 6px for workspace buttons
- CSS classes for workspace states:
  - `.focused`: Currently active workspace with keyboard focus
  - `.visible`: Workspace displayed on a monitor (not focused)
  - Default: Workspaces not visible on any monitor

### GTK CSS Limitations

When editing CSS, note that GTK CSS doesn't support:
- `transform` property (including `translateY`, `translateX`, etc.)
- Standard CSS animations (use `transition` instead)
- Many modern CSS features - stick to basic properties

## Common Commands

### Reload Waybar
```bash
pkill waybar && waybar &
```

### Switch Themes
```bash
./switch-theme.sh {nordic|synthwave|tokyonight|catppuccin|cyberpunk}
```

### Validate Configuration
```bash
# Check if config is valid JSON
python3 -m json.tool config.jsonc > /dev/null
```

### Check Current Theme
```bash
readlink style.css
```

## Module Configuration Notes

### Multi-Monitor Workspace Highlighting

The workspace styling is designed for multi-monitor setups. When editing workspace appearance:
- Always style both `.focused` (active workspace) and `.visible` (shown on other monitors)
- Use distinct visual differentiation so users can identify which workspaces are displayed across 1-3 monitors
- Never remove workspace button states without replacement styling

### Module States

Several modules support state-based styling (warning/critical/good):
- `#battery`: critical (15%), warning (30%), good (50%), charging
- `#cpu`: Add states in config.jsonc for warning (70%) and critical (90%) thresholds
- `#memory`: Add states in config.jsonc for warning (70%) and critical (90%) thresholds
- `#pulseaudio.muted`: Special styling when audio is muted

### Height Calculation

The bar height must accommodate module styling. Current modules require minimum 58px:
- Base padding: 6px top + 6px bottom = 12px
- Module margin: 4px top + 4px bottom = 8px
- Border: 1px top + 1px bottom = 2px
- Font size + line height ≈ 16-20px
- Box shadow space ≈ 4-8px
If Waybar logs "Requested height X is less than minimum height Y", update the `height` value in config.jsonc

## Theme Color Schemes

- **Nordic**: Nord color palette - cool blues, greens, and reds
- **Synthwave**: Hot pink (#ff00ff), cyan (#00ffff), purple - 80s neon aesthetic with glows
- **Tokyo Night**: Blue-black base (#1a1b26), electric blue (#7aa2f7), pastels
- **Catppuccin Mocha**: Mocha base (#1e1e2e) with lavender, pink, teal, peach accents
- **Cyberpunk**: Pure black (#000000), matrix green (#00ff00), cyan (#00ffff), red (#ff0000)

All themes use transparency (0.8-0.9 alpha) for depth and include box-shadow for neon glow effects.
