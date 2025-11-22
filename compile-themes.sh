#!/bin/bash
# Waybar Theme Compiler
# Generates CSS files from template + color configs

WAYBAR_DIR="$HOME/.config/waybar"
TEMPLATE="$WAYBAR_DIR/template.css"
THEMES_DIR="$WAYBAR_DIR/themes"

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Error: template.css not found"
    exit 1
fi

if [[ ! -d "$THEMES_DIR" ]]; then
    echo "Error: themes directory not found"
    exit 1
fi

# Compile each theme
for theme_conf in "$THEMES_DIR"/*.conf; do
    if [[ ! -f "$theme_conf" ]]; then
        continue
    fi

    theme_name=$(basename "$theme_conf" .conf)
    output_file="$WAYBAR_DIR/style-${theme_name}.css"

    echo "Compiling $theme_name..."

    # Start with template
    cp "$TEMPLATE" "$output_file"

    # Replace comment with theme name
    sed -i "s/WAYBAR THEME TEMPLATE/${theme_name^^} THEME/" "$output_file"

    # Read each variable and replace in output
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue

        # Trim whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        # Replace placeholder with value
        sed -i "s|{{$key}}|$value|g" "$output_file"
    done < "$theme_conf"

    echo "✓ Generated $output_file"
done

echo ""
echo "Theme compilation complete!"
echo "Run ./switch-theme.sh to switch themes"
