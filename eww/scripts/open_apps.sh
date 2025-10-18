#!/bin/bash
# ~/.config/eww/scripts/open_apps.sh

# Get all window titles from hyprctl clients
# Only non-empty titles, limit to 10
apps=$(hyprctl clients | awk -F'title: ' '/title:/ {gsub(/^[ \t]+|[ \t]+$/,"",$2); if($2!="") print $2}' | head -n 10)

for app in $apps; do
    # Escape double quotes for Yuck
    app_escaped=$(echo "$app" | sed 's/"/\\"/g')
    
    # Output as a Yuck label
    echo "(label :text \"$app_escaped\" :class \"side-bar-item\")"
done
