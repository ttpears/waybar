# Waybar Configuration for Sway

A highly customizable Waybar setup with a template-based multi-theme system. Features 10 beautiful themes with easy customization and minimal code duplication.

## Features

- **Template-based theme system** - 50% less code duplication
- **10 gorgeous themes** - Nordic, Synthwave, Tokyo Night, Catppuccin, Cyberpunk, Gruvbox, Dracula, One Dark, Solarized, Monokai
- **Multi-monitor support** - Proper workspace highlighting across 1-3 monitors
- **Easy theme creation** - Add new themes in minutes
- **Simple compilation** - Pure bash, no dependencies

## Themes

| Theme | Description |
|-------|-------------|
| **Nordic** | Cool Nordic/Nord color palette with blues, greens, and reds |
| **Synthwave** | Hot pink, cyan, and purple with 80s neon aesthetic and glows |
| **Tokyo Night** | Deep blue-black base with electric blue and pastel accents |
| **Catppuccin** | Mocha base with lavender, pink, teal, and peach accents |
| **Cyberpunk** | Pure black with matrix green, cyan, and red |
| **Gruvbox** | Warm retro palette with dark brown base, orange, green, and yellow |
| **Dracula** | Dark purple base with vibrant purple, cyan, and pink highlights |
| **One Dark** | Atom's iconic dark theme with blue, green, and purple accents |
| **Solarized** | Classic blue-tinted dark theme with balanced color palette |
| **Monokai** | Classic code editor theme with cyan, green, and pink on dark gray |

All themes use transparency (0.8-0.9 alpha) and neon glow effects for depth.

## Quick Start

### Installation

```bash
# Clone to your Waybar config directory
git clone https://github.com/ttpears/waybar ~/.config/waybar
cd ~/.config/waybar

# Run the setup wizard (checks dependencies, compiles themes, sets default)
./setup.sh

# Or do it manually:
./compile-themes.sh
./switch-theme.sh nordic
```

The setup wizard will:
- ✓ Check all dependencies
- ✓ Validate configuration files
- ✓ Compile themes if needed
- ✓ Set a default theme
- ✓ Detect unified Sway integration
- ✓ Show you next steps

### Usage

The theme switcher supports multiple modes:

**Interactive menu** (requires rofi, wofi, or fzf):
```bash
./switch-theme.sh menu
# or just
./switch-theme.sh
```

**Direct theme switch:**
```bash
./switch-theme.sh nordic
./switch-theme.sh synthwave
./switch-theme.sh gruvbox
./switch-theme.sh dracula
# ... etc (10 themes available)
```

**Cycle through themes:**
```bash
./switch-theme.sh next
```

**Show current theme:**
```bash
./switch-theme.sh current
```

**List all themes:**
```bash
./switch-theme.sh list
```

**Help:**
```bash
./switch-theme.sh help
```

## Customization

### Creating a New Theme

1. Copy an existing theme config:
   ```bash
   cp themes/nordic.conf themes/mytheme.conf
   ```

2. Edit the colors in `themes/mytheme.conf`:
   ```conf
   # My Theme Colors
   bg-bar=rgba(20, 20, 30, 0.9)
   text-primary=#ffffff
   # ... edit other colors ...
   ```

3. Compile and use:
   ```bash
   ./compile-themes.sh
   ./switch-theme.sh mytheme
   ```

### Modifying Structure

Edit `template.css` to change the layout or add new modules. Changes apply to all themes when recompiled.

### Theme Configuration Format

Each theme file (`themes/*.conf`) uses simple `key=value` pairs:

```conf
# Comments start with #
bg-bar=rgba(46, 52, 64, 0.9)
text-primary=#eceff4
ws-default=#88c0d0
# ... etc
```

See any theme file for the complete list of customizable properties.

## How It Works

The theme system uses a template + compilation approach:

1. **`template.css`** - Contains the entire CSS structure with placeholders like `{{bg-bar}}`
2. **`themes/*.conf`** - Simple config files with color values
3. **`compile-themes.sh`** - Bash script that does find/replace to generate final CSS files
4. **`switch-theme.sh`** - Updates the symlink and reloads Waybar

This avoids GTK CSS variable limitations while keeping themes DRY (Don't Repeat Yourself).

## Configuration Details

### Multi-Monitor Workspace Highlighting

Workspace styling differentiates between:
- `.focused` - Active workspace with keyboard focus
- `.visible` - Workspace displayed on another monitor
- Default - Workspaces not visible on any monitor

### Module States

Several modules support state-based styling:
- **Battery**: critical (15%), warning (30%), good (50%), charging
- **CPU/Memory**: warning (70%), critical (90%) - configure in config.jsonc
- **Pulseaudio**: muted state
- **Network**: disconnected, linked

### Bar Configuration

- **Position**: Bottom
- **Height**: 58px (minimum required for styled modules)
- **Font**: Iosevka Term Nerd Font (with fallbacks)
- **Multi-monitor**: Shows workspaces across all monitors

## Requirements

### Required
- Waybar (with Sway support)
- Bash (for compilation and theme switching)

### Recommended
- Nerd Font (Iosevka Term recommended, or any Nerd Font)
- One of: wofi, rofi, or fzf (for interactive menu)
- Sway window manager (for full integration)

**Tip:** Run `./setup.sh check` to validate your system

## Sway Integration

### Standalone Mode (Waybar themes only)

Add these keybindings to `~/.config/sway/config`:

```
# Start Waybar
exec waybar

# Interactive theme selector (Mod+Shift+T)
bindsym $mod+Shift+t exec ~/.config/waybar/switch-theme.sh menu

# Cycle through themes (Mod+Shift+N)
bindsym $mod+Shift+n exec ~/.config/waybar/switch-theme.sh next
```

See `sway-integration.conf` for more examples.

### Unified Mode (Sway + Waybar themes together)

For a complete themed desktop where Sway window manager colors match Waybar:

1. Create unified theme switcher in `~/.config/sway/`
2. Add matching Sway theme files
3. Use GUI wrapper with wofi for best UX

**See `INTEGRATION.md` for complete unified theme system setup.**

This gives you:
- Cohesive window borders + statusbar
- Single command switches everything
- Desktop notifications
- State persistence

## Contributing

Contributions welcome! To add a new theme:

1. Create a new `.conf` file in `themes/`
2. Follow the existing format
3. Test with `./compile-themes.sh && ./switch-theme.sh yourtheme`
4. Submit a pull request with screenshots

## License

MIT License - Feel free to use and modify for your own setup.

## Credits

Inspired by:
- [Nord Theme](https://www.nordtheme.com/)
- [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme)
- [Catppuccin](https://github.com/catppuccin/catppuccin)
- [Gruvbox](https://github.com/morhetz/gruvbox)
- [Dracula](https://draculatheme.com/)
- [One Dark](https://github.com/atom/one-dark-syntax)
- [Solarized](https://ethanschoonover.com/solarized/)
- [Monokai](https://monokai.pro/)
- Synthwave/Outrun aesthetic
- Cyberpunk/Matrix aesthetic
