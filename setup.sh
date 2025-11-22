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
# OS Detection
# ========================================

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

get_install_cmd() {
    local package="$1"
    local os=$(detect_os)

    case "$os" in
        arch|manjaro|endeavouros)
            echo "sudo pacman -S $package"
            ;;
        ubuntu|debian|pop|linuxmint|elementary)
            echo "sudo apt install $package"
            ;;
        fedora)
            echo "sudo dnf install $package"
            ;;
        opensuse*|suse)
            echo "sudo zypper install $package"
            ;;
        void)
            echo "sudo xbps-install -S $package"
            ;;
        gentoo)
            echo "sudo emerge $package"
            ;;
        *)
            echo "# Install $package using your package manager"
            ;;
    esac
}

get_os_name() {
    local os=$(detect_os)
    case "$os" in
        arch) echo "Arch Linux" ;;
        manjaro) echo "Manjaro" ;;
        ubuntu) echo "Ubuntu" ;;
        debian) echo "Debian" ;;
        fedora) echo "Fedora" ;;
        pop) echo "Pop!_OS" ;;
        opensuse*) echo "openSUSE" ;;
        void) echo "Void Linux" ;;
        gentoo) echo "Gentoo" ;;
        *) echo "Unknown" ;;
    esac
}

# ========================================
# Validation Functions
# ========================================

check_fonts() {
    print_header "Checking Fonts"

    local fonts_ok=false

    # Check if fc-list is available
    if ! command -v fc-list &> /dev/null; then
        print_warning "fontconfig not installed - cannot check fonts"
        print_info "    Install fontconfig: $(get_install_cmd fontconfig)"
        return 0
    fi

    # Check for common Nerd Font installations
    if fc-list | grep -i "nerd font" > /dev/null 2>&1; then
        print_success "Nerd Font detected"

        # Show which ones
        local nerd_fonts=$(fc-list | grep -i "nerd font" | cut -d: -f2 | cut -d, -f1 | sort -u | head -5)
        while IFS= read -r font; do
            [[ -n "$font" ]] && print_info "    → $font"
        done <<< "$nerd_fonts"
        fonts_ok=true
    else
        print_warning "No Nerd Fonts detected"
        print_info "    Waybar will work, but icons may not display correctly"

        local os=$(detect_os)
        echo ""
        case "$os" in
            arch|manjaro|endeavouros)
                print_info "Install Nerd Fonts on $(get_os_name):"
                echo -e "    ${GREEN}sudo pacman -S ttf-iosevka-nerd${NC}"
                echo -e "    ${GREEN}# Or from AUR: yay -S nerd-fonts-iosevka${NC}"
                ;;
            ubuntu|debian|pop|linuxmint)
                print_info "Install Nerd Fonts on $(get_os_name):"
                echo -e "    ${GREEN}mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts${NC}"
                echo -e "    ${GREEN}wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Iosevka.zip${NC}"
                echo -e "    ${GREEN}unzip Iosevka.zip && rm Iosevka.zip && fc-cache -fv${NC}"
                ;;
            fedora)
                print_info "Install Nerd Fonts on $(get_os_name):"
                echo -e "    ${GREEN}sudo dnf copr enable che/nerd-fonts${NC}"
                echo -e "    ${GREEN}sudo dnf install iosevka-nerd-fonts${NC}"
                ;;
            *)
                print_info "Install Nerd Fonts manually:"
                echo -e "    Visit: ${BLUE}https://www.nerdfonts.com/font-downloads${NC}"
                ;;
        esac
        echo ""
    fi

    return 0
}

check_dependencies() {
    print_header "Checking Dependencies"

    local all_ok=true
    local missing_packages=()

    # Required
    if command -v waybar &> /dev/null; then
        print_success "Waybar installed"
    else
        print_error "Waybar not found (REQUIRED)"
        missing_packages+=("waybar")
        all_ok=false
    fi

    # Theme compilation
    if command -v bash &> /dev/null; then
        print_success "Bash available"
    else
        print_error "Bash not found (REQUIRED)"
        missing_packages+=("bash")
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
        print_warning "No interactive menu program found"
        print_info "    Install one of: wofi, rofi, or fzf for interactive theme switching"
        missing_packages+=("wofi")
    fi

    # Sway integration check
    if command -v swaymsg &> /dev/null; then
        print_success "Sway installed"
    else
        print_warning "Sway not found (optional - needed for Sway integration)"
    fi

    # Show summary if packages are missing
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        echo ""
        print_warning "Missing packages detected"
        print_info "Detected OS: $(get_os_name)"
        echo ""
        print_info "Install commands:"

        for pkg in "${missing_packages[@]}"; do
            echo -e "    ${GREEN}$(get_install_cmd "$pkg")${NC}"
        done
        echo ""
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
            [[ -f "$css_file" ]] || continue
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

        if [[ -f "$WAYBAR_DIR/$target" ]] || [[ -f "$target" ]]; then
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
        if grep -q "waybar.*switch-theme\|switch-theme.*waybar" "$SWAY_DIR/config" 2>/dev/null; then
            print_success "Theme switcher keybinding found in Sway config"
        else
            print_warning "No theme switcher keybinding found in Sway config"
            print_info "    See sway-integration.conf for setup instructions"
        fi

        # Check for unified setup
        if [[ -f "$SWAY_DIR/switch-theme.sh" ]] || [[ -f "$SWAY_DIR/switch-theme-gui.sh" ]]; then
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
    local available_themes=($(find "$WAYBAR_DIR" -name "style-*.css" -type f -exec basename {} .css \; 2>/dev/null | sed 's/style-//'))

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

    echo -e "Your Waybar theme system is ready! Here's what you can do:"
    echo -e ""
    echo -e "1. Switch themes interactively:"
    echo -e "   ${GREEN}./switch-theme.sh menu${NC}"
    echo -e ""
    echo -e "2. Switch to a specific theme:"
    echo -e "   ${GREEN}./switch-theme.sh nordic${NC}"
    echo -e ""
    echo -e "3. Cycle to next theme:"
    echo -e "   ${GREEN}./switch-theme.sh next${NC}"
    echo -e ""
    echo -e "4. Add Sway keybindings (recommended):"
    echo -e "   See ${BLUE}sway-integration.conf${NC} for examples"
    echo -e ""
    echo -e "5. Create new themes:"
    echo -e "   Copy a theme from ${BLUE}themes/${NC} and edit colors"
    echo -e "   Run ${GREEN}./compile-themes.sh${NC} to generate CSS"
    echo -e ""

    if command -v swaymsg &> /dev/null; then
        echo -e "6. Reload Waybar to see changes:"
        echo -e "   ${GREEN}pkill waybar && waybar &${NC}"
        echo -e ""
    fi
}

# ========================================
# Main Setup Flow
# ========================================

run_checks() {
    local all_ok=true

    check_dependencies || all_ok=false
    check_fonts
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
            check_fonts
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
