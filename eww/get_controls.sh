#!/bin/bash

while true; do
    # --- Brightness ---
    # Gets current and max brightness to calculate a percentage
    BRIGHTNESS_CURRENT=$(brightnessctl g)
    BRIGHTNESS_MAX=$(brightnessctl m)
    BRIGHTNESS_PERC=$((BRIGHTNESS_CURRENT * 100 / BRIGHTNESS_MAX))

    # --- Volume ---
    # Gets volume percentage and mute status from PulseAudio/PipeWire
    VOLUME_PERC=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -n 1 | tr -d '%')
    MUTE_STATUS=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '/Mute/ {print $2}')

    # --- Output JSON ---
    echo "{\"brightness\": $BRIGHTNESS_PERC, \"volume\": $VOLUME_PERC, \"mute\": \"$MUTE_STATUS\"}"

    sleep 1
done
