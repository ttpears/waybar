# Waybar Theme Integration Guide

This document explains different ways to integrate the Waybar theme system with your Sway setup.

## Option 1: Waybar-Only Theme Switching (Standalone)

Use the built-in `switch-theme.sh` for Waybar themes only.

### Setup

```bash
# Compile themes
cd ~/.config/waybar
./compile-themes.sh

# Add to ~/.config/sway/config
bindsym $mod+Shift+t exec ~/.config/waybar/switch-theme.sh menu
bindsym $mod+Shift+n exec ~/.config/waybar/switch-theme.sh next
```

### Features
- Interactive menu (rofi/wofi/fzf)
- Theme cycling
- List/show current theme

See `sway-integration.conf` for complete examples.

---

## Option 2: Unified Sway + Waybar Theme Switching (Advanced)

Coordinate Sway window manager themes with Waybar themes for a fully cohesive look.

### Architecture

```
~/.config/sway/
├── config                      # Main Sway config
├── themes/                     # Sway theme files (colors, borders, etc.)
│   ├── nordic
│   ├── synthwave
│   ├── tokyonight
│   ├── catppuccin
│   └── cyberpunk
├── switch-theme.sh             # Unified switcher (both Sway + Waybar)
├── switch-theme-gui.sh         # GUI wrapper with wofi
└── .current_theme              # State file (current theme)

~/.config/waybar/
├── themes/                     # Waybar theme configs
├── template.css                # Waybar template
├── compile-themes.sh           # Generate Waybar CSS
└── style-*.css                 # Generated CSS files
```

### Unified Switcher Script

Create `~/.config/sway/switch-theme.sh`:

```bash
#!/bin/bash
# Unified Theme Switcher for Sway + Waybar

SWAY_CONFIG="$HOME/.config/sway/config"
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
THEME_STATE_FILE="$HOME/.config/sway/.current_theme"

THEMES=("nordic" "synthwave" "tokyonight" "catppuccin" "cyberpunk")

# Get current theme from state file
get_current_theme() {
    if [[ -f "$THEME_STATE_FILE" ]]; then
        cat "$THEME_STATE_FILE"
    else
        echo "nordic"
    fi
}

# Validate theme exists
validate_theme() {
    local theme="$1"
    for valid_theme in "${THEMES[@]}"; do
        [[ "$theme" == "$valid_theme" ]] && return 0
    done
    return 1
}

# Switch Sway theme (colors, borders, gaps, etc.)
switch_sway_theme() {
    local theme="$1"
    local theme_file="$HOME/.config/sway/themes/$theme"

    [[ ! -f "$theme_file" ]] && return 1

    # Update include line in Sway config
    sed -i "s|^include ~/.config/sway/themes/.*|include ~/.config/sway/themes/$theme|" "$SWAY_CONFIG"
    return 0
}

# Switch Waybar theme (CSS)
switch_waybar_theme() {
    local theme="$1"
    local style_file="$WAYBAR_CONFIG_DIR/style-$theme.css"

    [[ ! -f "$style_file" ]] && return 1

    # Update symlink
    ln -sf "style-$theme.css" "$WAYBAR_CONFIG_DIR/style.css"
    return 0
}

# Reload both Sway and Waybar
reload_all() {
    swaymsg reload
    pkill waybar
    waybar &
    disown
}

# Main logic
main() {
    local new_theme="${1:-$(get_current_theme)}"

    if ! validate_theme "$new_theme"; then
        echo "Error: Invalid theme '$new_theme'"
        echo "Available: ${THEMES[*]}"
        exit 1
    fi

    echo "Switching to: $new_theme"

    switch_sway_theme "$new_theme" || exit 1
    switch_waybar_theme "$new_theme" || exit 1

    echo "$new_theme" > "$THEME_STATE_FILE"

    reload_all
    echo "Theme switched successfully!"
}

main "$@"
```

### GUI Wrapper with Wofi

Create `~/.config/sway/switch-theme-gui.sh`:

```bash
#!/bin/bash
# GUI Theme Switcher for Sway + Waybar

THEME_SWITCHER="$HOME/.config/sway/switch-theme.sh"
THEME_STATE_FILE="$HOME/.config/sway/.current_theme"

declare -A DESCRIPTIONS=(
    ["nordic"]="Nordic - Frost and aurora"
    ["synthwave"]="Synthwave - Neon outrun"
    ["tokyonight"]="Tokyo Night - Dark blue"
    ["catppuccin"]="Catppuccin - Pastel dark"
    ["cyberpunk"]="Cyberpunk - Matrix green"
)

THEMES=("nordic" "synthwave" "tokyonight" "catppuccin" "cyberpunk")

get_current_theme() {
    [[ -f "$THEME_STATE_FILE" ]] && cat "$THEME_STATE_FILE" || echo "nordic"
}

build_menu() {
    local current=$(get_current_theme)
    for theme in "${THEMES[@]}"; do
        local marker="  "
        [[ "$theme" == "$current" ]] && marker="● "
        echo "${marker}${theme} - ${DESCRIPTIONS[$theme]}"
    done
}

main() {
    local selected=""

    if command -v wofi &> /dev/null; then
        selected=$(build_menu | wofi \
            --dmenu \
            --prompt "Select theme:" \
            --insensitive \
            --height 300 \
            --width 500 \
            --cache-file /dev/null)
    elif command -v rofi &> /dev/null; then
        selected=$(build_menu | rofi \
            -dmenu -i \
            -p "Select theme:")
    else
        notify-send "Theme Switcher" "No menu program found" --urgency=critical
        exit 1
    fi

    [[ -z "$selected" ]] && exit 0

    # Extract theme name (remove marker and description)
    local theme=$(echo "$selected" | sed -E 's/^[● ] +([a-z]+) -.*/\1/')

    if [[ -n "$theme" ]]; then
        if "$THEME_SWITCHER" "$theme"; then
            notify-send "Theme Switcher" "Switched to $theme" --urgency=normal
        else
            notify-send "Theme Switcher" "Failed to switch theme" --urgency=critical
        fi
    fi
}

main "$@"
```

Make scripts executable:
```bash
chmod +x ~/.config/sway/switch-theme.sh
chmod +x ~/.config/sway/switch-theme-gui.sh
```

### Sway Keybindings

Add to `~/.config/sway/config`:

```
# Unified theme switcher
bindsym $mod+Shift+t exec ~/.config/sway/switch-theme-gui.sh
bindsym $mod+Shift+n exec ~/.config/sway/switch-theme.sh  # cycles to next theme
```

### Sway Theme Files

Create matching theme files in `~/.config/sway/themes/`. Example for `nordic`:

```
# Nordic Theme Colors
set $bg     #2e3440
set $fg     #eceff4
set $accent #88c0d0

# Window colors
#                       border  bg      text    indicator child_border
client.focused          $accent $accent $bg     $accent   $accent
client.focused_inactive #4c566a #4c566a $fg     #4c566a   #4c566a
client.unfocused        #3b4252 #3b4252 #d8dee9 #3b4252   #3b4252
client.urgent           #bf616a #bf616a $fg     #bf616a   #bf616a

# Borders and gaps
default_border pixel 2
gaps inner 10
gaps outer 5
```

Update `~/.config/sway/config` to include theme:

```
# Theme (dynamically updated by switch-theme.sh)
include ~/.config/sway/themes/nordic
```

### Benefits of Unified Approach

- **Cohesive aesthetics** - Sway windows, borders, and Waybar all match
- **Single command** - One theme switch affects everything
- **State persistence** - Remembers your choice across restarts
- **Desktop notifications** - Visual feedback when switching
- **Clean separation** - Sway handles WM themes, Waybar handles statusbar themes

---

## Comparison

| Feature | Standalone | Unified |
|---------|-----------|---------|
| Waybar themes | ✅ | ✅ |
| Sway themes | ❌ | ✅ |
| State file | ❌ | ✅ |
| Notifications | ❌ | ✅ |
| Single switch | ❌ | ✅ |
| Complexity | Low | Medium |

Choose standalone for simplicity, unified for a complete themed desktop experience.
