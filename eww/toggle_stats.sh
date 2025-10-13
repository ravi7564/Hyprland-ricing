#!/bin/bash

# A reliable script to toggle an Eww window.

# First, check if the Eww daemon is running. If not, start it.
if ! pgrep -x eww >/dev/null; then
    eww daemon
    sleep 0.2
fi

# Use grep -q to check if the window is active without printing output.
if eww active-windows | grep -q "sys-hud"; then
  # If grep finds a match (exit code 0), the window is open, so close it.
  eww close sys-hud
else
  # If grep finds no match (exit code 1), the window is not open, so open it.
  eww open sys-hud
fi
