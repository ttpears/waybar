# Setup Helper Script

The `setup.sh` script provides intelligent deployment and validation for the Waybar theme system.

## Quick Start

```bash
# Run interactive setup wizard
./setup.sh

# Just check status
./setup.sh check

# Recompile all themes
./setup.sh compile

# Validate configuration only
./setup.sh validate
```

## What It Checks

### Dependencies
- ✓ Waybar installed
- ✓ Bash available
- ✓ Interactive menu programs (wofi/rofi/fzf)
- ✓ Sway integration (optional)

### Configuration
- ✓ config.jsonc exists and is valid JSON
- ✓ template.css present
- ✓ Theme configs in themes/ directory
- ✓ Compiled CSS files exist
- ✓ Current theme symlink is valid

### Integration
- ✓ Detects unified Sway + Waybar setup
- ✓ Checks for Sway theme files
- ✓ Verifies keybindings in Sway config
- ✓ Shows current mode (standalone vs unified)

## First-Time Setup

When run for the first time, the script will:

1. **Check all dependencies** - Verify required software is installed
2. **Validate configuration** - Ensure all config files are present and valid
3. **Offer to compile themes** - Generate CSS from templates if needed
4. **Set default theme** - Create initial symlink to Nordic theme
5. **Show next steps** - Provide helpful commands to get started

## Commands

### setup (default)
Interactive wizard that walks through the entire setup process:
```bash
./setup.sh
./setup.sh setup
```

### check
Run all validation checks without making changes:
```bash
./setup.sh check
```

Output example:
```
========================================
Checking Dependencies
========================================
✓ Waybar installed
✓ Wofi installed (interactive menu)
✓ Sway installed

========================================
Current Theme Status
========================================
✓ Active theme: tokyonight
✓ Theme file exists and is linked
```

### compile
Compile or recompile all themes:
```bash
./setup.sh compile
```

Useful after:
- Editing theme configs in `themes/*.conf`
- Modifying `template.css`
- Adding new themes

### validate
Quick validation of dependencies and config files:
```bash
./setup.sh validate
```

## Troubleshooting

### No compiled themes found
```bash
./setup.sh compile
```

### Theme symlink broken
```bash
./switch-theme.sh nordic  # or any theme name
```

### Waybar won't start
```bash
# Check config
./setup.sh validate

# Reload Waybar
pkill waybar && waybar &
```

### Want to see what's installed
```bash
./setup.sh check
```

## Exit Codes

- `0` - Success
- `1` - Error (with helpful message)

The script is safe to run multiple times - it's idempotent and won't break existing setups.

## Features

- **Smart detection** - Auto-detects unified Sway setup vs standalone
- **Colored output** - Easy to read status messages
- **Interactive prompts** - Asks before making changes
- **Comprehensive checks** - Validates entire system
- **Helpful next steps** - Shows commands to get started
- **Non-destructive** - Won't overwrite working configurations
