#!/bin/bash

# File to store toggle state
STATE_FILE="$HOME/.config/eww/sys_hud_state"

# Ensure daemon is running
if ! pgrep -x eww >/dev/null; then
    eww daemon &
    sleep 0.2
fi

# Read previous state
if [ -f "$STATE_FILE" ]; then
    STATE=$(cat "$STATE_FILE")
else
    STATE="closed"
fi

# Toggle
if [ "$STATE" = "closed" ]; then
    eww open sys-hud
    echo "open" > "$STATE_FILE"
else
    eww close sys-hud
    echo "closed" > "$STATE_FILE"
fi
