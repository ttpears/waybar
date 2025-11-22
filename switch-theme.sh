#!/bin/bash
# Waybar Theme Switcher with Interactive Menu Support

WAYBAR_DIR="$HOME/.config/waybar"
THEMES_DIR="$WAYBAR_DIR/themes"

# Theme metadata (name:description)
declare -A THEME_INFO=(
    ["nordic"]="Cool Nordic/Nord colors"
    ["synthwave"]="Hot pink, cyan, purple neon (Outrun)"
    ["tokyonight"]="Deep blue with electric accents"
    ["catppuccin"]="Rich pastels on mocha base"
    ["cyberpunk"]="Matrix green with neon cyan"
    ["gruvbox"]="Warm retro browns and oranges"
    ["dracula"]="Dark purple with vibrant accents"
    ["onedark"]="Atom's iconic dark theme"
    ["solarized"]="Classic blue-tinted dark theme"
    ["monokai"]="Classic code editor palette"
)

# Get current theme
get_current_theme() {
    if [[ -L "$WAYBAR_DIR/style.css" ]]; then
        local target=$(readlink "$WAYBAR_DIR/style.css")
        basename "$target" | sed 's/style-\(.*\)\.css/\1/'
    else
        echo "none"
    fi
}

# Get list of available themes
get_available_themes() {
    if [[ -d "$THEMES_DIR" ]]; then
        find "$THEMES_DIR" -name "*.conf" -type f -printf "%f\n" | sed 's/\.conf$//' | sort
    fi
}

# Switch to a theme
switch_theme() {
    local theme="$1"
    local theme_file="$WAYBAR_DIR/style-${theme}.css"

    if [[ ! -f "$theme_file" ]]; then
        echo "Error: Theme '$theme' not found. Run ./compile-themes.sh first."
        return 1
    fi

    ln -sf "$theme_file" "$WAYBAR_DIR/style.css"
    echo "Switched to ${theme^} theme"

    # Reload waybar
    pkill waybar
    waybar &
}

# Show current theme
show_current() {
    local current=$(get_current_theme)
    if [[ "$current" != "none" ]]; then
        echo "Current theme: ${current^}"
        if [[ -n "${THEME_INFO[$current]}" ]]; then
            echo "  ${THEME_INFO[$current]}"
        fi
    else
        echo "No theme currently set"
    fi
}

# Interactive theme selector using rofi/wofi/fzf
interactive_menu() {
    local current=$(get_current_theme)
    local menu_cmd=""

    # Detect available menu program
    if command -v rofi &> /dev/null; then
        menu_cmd="rofi -dmenu -i -p 'Select Theme'"
    elif command -v wofi &> /dev/null; then
        menu_cmd="wofi --dmenu -i -p 'Select Theme'"
    elif command -v fzf &> /dev/null; then
        menu_cmd="fzf --prompt='Select Theme: ' --height=40%"
    else
        echo "Error: No menu program found (rofi, wofi, or fzf required)"
        return 1
    fi

    # Build menu with current theme marked
    local menu_items=""
    while IFS= read -r theme; do
        local marker=""
        [[ "$theme" == "$current" ]] && marker="✓ "
        local desc="${THEME_INFO[$theme]}"
        menu_items+="${marker}${theme}|${desc}\n"
    done < <(get_available_themes)

    # Show menu and get selection
    local selection=$(echo -e "$menu_items" | column -t -s'|' | $menu_cmd)

    if [[ -n "$selection" ]]; then
        # Extract theme name (remove marker and description)
        local chosen_theme=$(echo "$selection" | awk '{print $1}' | sed 's/✓ //')
        switch_theme "$chosen_theme"
    fi
}

# Cycle to next theme
cycle_theme() {
    local current=$(get_current_theme)
    local themes=($(get_available_themes))
    local next_theme=""

    if [[ "$current" == "none" ]] || [[ ${#themes[@]} -eq 0 ]]; then
        next_theme="${themes[0]}"
    else
        for i in "${!themes[@]}"; do
            if [[ "${themes[$i]}" == "$current" ]]; then
                local next_idx=$(( (i + 1) % ${#themes[@]} ))
                next_theme="${themes[$next_idx]}"
                break
            fi
        done
    fi

    if [[ -n "$next_theme" ]]; then
        switch_theme "$next_theme"
    fi
}

# List all available themes
list_themes() {
    echo "Available themes:"
    local current=$(get_current_theme)

    while IFS= read -r theme; do
        local marker=" "
        [[ "$theme" == "$current" ]] && marker="*"
        local desc="${THEME_INFO[$theme]}"
        printf "  %s %-12s - %s\n" "$marker" "$theme" "$desc"
    done < <(get_available_themes)
}

# Main logic
case "$1" in
    current|status)
        show_current
        ;;
    menu|interactive)
        interactive_menu
        ;;
    next|cycle)
        cycle_theme
        ;;
    list|ls)
        list_themes
        ;;
    nordic|synthwave|tokyonight|catppuccin|cyberpunk|gruvbox|dracula|onedark|solarized|monokai)
        switch_theme "$1"
        ;;
    "")
        # No args - try interactive menu
        if command -v rofi &> /dev/null || command -v wofi &> /dev/null || command -v fzf &> /dev/null; then
            interactive_menu
        else
            list_themes
            echo ""
            echo "Usage: $0 {theme-name|menu|next|current|list}"
        fi
        ;;
    -h|--help|help)
        echo "Waybar Theme Switcher"
        echo ""
        echo "Usage: $0 [command|theme-name]"
        echo ""
        echo "Commands:"
        echo "  menu, interactive  - Show interactive theme selector"
        echo "  next, cycle       - Cycle to next theme"
        echo "  current, status   - Show current theme"
        echo "  list, ls          - List available themes"
        echo "  help              - Show this help"
        echo ""
        echo "Theme Names:"
        while IFS= read -r theme; do
            printf "  %-12s - %s\n" "$theme" "${THEME_INFO[$theme]}"
        done < <(get_available_themes)
        echo ""
        echo "Examples:"
        echo "  $0              - Show interactive menu (if available)"
        echo "  $0 menu         - Show interactive menu"
        echo "  $0 nordic       - Switch to Nordic theme"
        echo "  $0 next         - Cycle to next theme"
        echo "  $0 current      - Show current theme"
        ;;
    *)
        echo "Error: Unknown command or theme '$1'"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
