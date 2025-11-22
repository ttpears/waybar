#!/bin/bash
# ========================================
# Waybar Theme System Setup & Validation
# Intelligent deployment and configuration checker
# ========================================

set -e

WAYBAR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWAY_DIR="$HOME/.config/sway"
THEMES_DIR="$WAYBAR_DIR/themes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symbols
CHECK="✓"
CROSS="✗"
INFO="ℹ"
WARN="⚠"

# ========================================
# Helper Functions
# ========================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}${WARN}${NC} $1"
}

print_info() {
    echo -e "${BLUE}${INFO}${NC} $1"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" response
    response=${response:-$default}

    [[ "$response" =~ ^[Yy]$ ]]
}

# ========================================
# Validation Functions
# ========================================

check_dependencies() {
    print_header "Checking Dependencies"

    local all_ok=true

    # Required
    if command -v waybar &> /dev/null; then
        print_success "Waybar installed"
    else
        print_error "Waybar not found (REQUIRED)"
        all_ok=false
    fi

    # Theme compilation
    if command -v bash &> /dev/null; then
        print_success "Bash available"
    else
        print_error "Bash not found (REQUIRED)"
        all_ok=false
    fi

    # Interactive menu (at least one needed)
    local menu_found=false
    if command -v wofi &> /dev/null; then
        print_success "Wofi installed (interactive menu)"
        menu_found=true
    fi
    if command -v rofi &> /dev/null; then
        print_success "Rofi installed (interactive menu)"
        menu_found=true
    fi
    if command -v fzf &> /dev/null; then
        print_success "Fzf installed (interactive menu)"
        menu_found=true
    fi

    if ! $menu_found; then
        print_warning "No interactive menu program found (install wofi, rofi, or fzf)"
        print_info "    Theme switching will work, but interactive menu won't be available"
    fi

    # Sway integration check
    if command -v swaymsg &> /dev/null; then
        print_success "Sway installed"
    else
        print_warning "Sway not found (optional - needed for Sway integration)"
    fi

    $all_ok
}

check_config() {
    print_header "Validating Configuration"

    # Check config.jsonc
    if [[ -f "$WAYBAR_DIR/config.jsonc" ]]; then
        print_success "config.jsonc exists"

        # Try to validate JSON (strip comments first)
        if command -v python3 &> /dev/null; then
            if grep -v '^\s*//' "$WAYBAR_DIR/config.jsonc" | python3 -m json.tool > /dev/null 2>&1; then
                print_success "config.jsonc is valid JSON"
            else
                print_warning "config.jsonc may have syntax errors"
            fi
        fi
    else
        print_error "config.jsonc not found"
        return 1
    fi

    # Check template
    if [[ -f "$WAYBAR_DIR/template.css" ]]; then
        print_success "template.css exists"
    else
        print_error "template.css not found"
        return 1
    fi

    # Check theme configs
    local theme_count=$(find "$THEMES_DIR" -name "*.conf" -type f 2>/dev/null | wc -l)
    if [[ $theme_count -gt 0 ]]; then
        print_success "Found $theme_count theme configuration(s)"
    else
        print_error "No theme configs found in themes/"
        return 1
    fi

    return 0
}

check_compiled_themes() {
    print_header "Checking Compiled Themes"

    local compiled_count=$(find "$WAYBAR_DIR" -name "style-*.css" -type f 2>/dev/null | wc -l)

    if [[ $compiled_count -eq 0 ]]; then
        print_warning "No compiled theme files found"
        return 1
    else
        print_success "Found $compiled_count compiled theme(s)"

        # List them
        for css_file in "$WAYBAR_DIR"/style-*.css; do
            local theme_name=$(basename "$css_file" .css | sed 's/style-//')
            print_info "    → $theme_name"
        done

        return 0
    fi
}

check_current_theme() {
    print_header "Current Theme Status"

    if [[ -L "$WAYBAR_DIR/style.css" ]]; then
        local target=$(readlink "$WAYBAR_DIR/style.css")
        local theme_name=$(basename "$target" .css | sed 's/style-//')
        print_success "Active theme: $theme_name"

        if [[ -f "$WAYBAR_DIR/$target" ]]; then
            print_success "Theme file exists and is linked"
        else
            print_error "Theme file missing: $target"
            return 1
        fi
    else
        print_warning "No theme currently active (style.css symlink missing)"
        return 1
    fi

    return 0
}

check_sway_integration() {
    print_header "Sway Integration Status"

    if ! command -v swaymsg &> /dev/null; then
        print_info "Sway not installed - skipping integration check"
        return 0
    fi

    # Check if Sway config references our theme switcher
    if [[ -f "$SWAY_DIR/config" ]]; then
        if grep -q "waybar.*switch-theme" "$SWAY_DIR/config" 2>/dev/null; then
            print_success "Theme switcher keybinding found in Sway config"
        else
            print_warning "No theme switcher keybinding found in Sway config"
            print_info "    See sway-integration.conf for setup instructions"
        fi

        # Check for unified setup
        if [[ -f "$SWAY_DIR/switch-theme.sh" ]]; then
            print_success "Unified theme switcher detected in ~/.config/sway"

            if [[ -d "$SWAY_DIR/themes" ]]; then
                local sway_theme_count=$(find "$SWAY_DIR/themes" -type f 2>/dev/null | wc -l)
                print_success "Found $sway_theme_count Sway theme file(s)"
                print_info "    Using unified Sway + Waybar theme switching"
            fi
        else
            print_info "Standalone mode (Waybar themes only)"
        fi
    else
        print_warning "Sway config not found at $SWAY_DIR/config"
    fi

    return 0
}

# ========================================
# Setup Functions
# ========================================

compile_themes() {
    print_header "Compiling Themes"

    if [[ ! -x "$WAYBAR_DIR/compile-themes.sh" ]]; then
        print_error "compile-themes.sh not found or not executable"
        return 1
    fi

    print_info "Running theme compiler..."
    if "$WAYBAR_DIR/compile-themes.sh"; then
        print_success "Themes compiled successfully"
        return 0
    else
        print_error "Theme compilation failed"
        return 1
    fi
}

set_default_theme() {
    print_header "Setting Default Theme"

    local default_theme="nordic"

    # Check if any compiled themes exist
    local available_themes=($(find "$WAYBAR_DIR" -name "style-*.css" -type f -exec basename {} .css \; | sed 's/style-//'))

    if [[ ${#available_themes[@]} -eq 0 ]]; then
        print_error "No compiled themes available"
        return 1
    fi

    # If nordic doesn't exist, use first available
    if [[ ! -f "$WAYBAR_DIR/style-nordic.css" ]]; then
        default_theme="${available_themes[0]}"
    fi

    print_info "Setting default theme to: $default_theme"

    if ln -sf "style-${default_theme}.css" "$WAYBAR_DIR/style.css"; then
        print_success "Default theme set to $default_theme"
        return 0
    else
        print_error "Failed to set default theme"
        return 1
    fi
}

show_next_steps() {
    print_header "Next Steps"

    echo "Your Waybar theme system is ready! Here's what you can do:"
    echo ""
    echo "1. Switch themes interactively:"
    echo "   ${GREEN}./switch-theme.sh menu${NC}"
    echo ""
    echo "2. Switch to a specific theme:"
    echo "   ${GREEN}./switch-theme.sh nordic${NC}"
    echo ""
    echo "3. Cycle to next theme:"
    echo "   ${GREEN}./switch-theme.sh next${NC}"
    echo ""
    echo "4. Add Sway keybindings (recommended):"
    echo "   See ${BLUE}sway-integration.conf${NC} for examples"
    echo ""
    echo "5. Create new themes:"
    echo "   Copy a theme from ${BLUE}themes/${NC} and edit colors"
    echo "   Run ${GREEN}./compile-themes.sh${NC} to generate CSS"
    echo ""

    if command -v swaymsg &> /dev/null; then
        echo "6. Reload Waybar to see changes:"
        echo "   ${GREEN}pkill waybar && waybar &${NC}"
        echo ""
    fi
}

# ========================================
# Main Setup Flow
# ========================================

run_checks() {
    local all_ok=true

    check_dependencies || all_ok=false
    check_config || all_ok=false

    if ! check_compiled_themes; then
        all_ok=false

        if ask_yes_no "Would you like to compile themes now?" "y"; then
            compile_themes || all_ok=false
        fi
    fi

    if ! check_current_theme; then
        if ask_yes_no "Would you like to set a default theme?" "y"; then
            set_default_theme || all_ok=false
        fi
    fi

    check_sway_integration

    return 0
}

run_setup() {
    echo -e "${BLUE}"
    cat << "EOF"
╦ ╦┌─┐┬ ┬┌┐ ┌─┐┬─┐  ╔╦╗┬ ┬┌─┐┌┬┐┌─┐  ╔═╗┌─┐┌┬┐┬ ┬┌─┐
║║║├─┤└┬┘├┴┐├─┤├┬┘   ║ ├─┤├┤ │││├┤   ╚═╗├┤  │ │ │├─┘
╚╩╝┴ ┴ ┴ └─┘┴ ┴┴└─   ╩ ┴ ┴└─┘┴ ┴└─┘  ╚═╝└─┘ ┴ └─┘┴
EOF
    echo -e "${NC}"

    print_info "This script will help you set up the Waybar theme system"
    print_info "Current directory: $WAYBAR_DIR"
    echo ""

    run_checks

    echo ""
    show_next_steps
}

# ========================================
# CLI Interface
# ========================================

show_help() {
    cat << EOF
Waybar Theme System Setup & Validation

Usage: $0 [command]

Commands:
  setup         - Interactive setup wizard (default)
  check         - Run system checks only
  compile       - Compile all themes
  validate      - Validate configuration files
  help          - Show this help message

Examples:
  $0              # Run interactive setup
  $0 check        # Check current status
  $0 compile      # Recompile all themes

EOF
}

main() {
    cd "$WAYBAR_DIR"

    case "${1:-setup}" in
        setup)
            run_setup
            ;;
        check)
            run_checks
            ;;
        compile)
            compile_themes
            ;;
        validate)
            check_dependencies
            check_config
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
