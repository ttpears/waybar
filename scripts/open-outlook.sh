#!/bin/bash

# Find existing Outlook windows (PWA, browser, or native app)
outlook_window=$(swaymsg -t get_tree | jq -r '
  .. |
  select(.type? == "con") |
  select(.name? // "" | test("Outlook|outlook"; "i")) |
  .id' | head -n1)

if [ -n "$outlook_window" ]; then
  # Focus existing window
  swaymsg "[con_id=$outlook_window] focus"
else
  # No window found, launch Outlook
  /opt/outlook-for-linux/outlook-for-linux &
fi
