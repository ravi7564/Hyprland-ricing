#!/bin/bash

# This script runs Cava and sanitizes its output for Eww's JSON parser.
# It escapes backslashes and quotes and wraps the output in a JSON object.

# Use stdbuf to prevent buffering issues
stdbuf -oL cava -p ~/.config/cava/eww-config | while read -r line; do
  # Escape backslashes and double quotes
  sanitized_line=$(echo "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
  # Output as a JSON object
  echo "{\"bars\": \"$sanitized_line\"}"
done