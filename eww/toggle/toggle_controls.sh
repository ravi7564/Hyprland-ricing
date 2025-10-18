#!/bin/bash

# Get the list of active Eww windows
STATE=$(eww active-windows | grep "controls-widget")

if [ -z "$STATE" ]; then
  # If the variable is empty, the window is not open, so open it
  eww open controls-widget
else
  # If the variable is not empty, the window is open, so close it
  eww close controls-widget
fi
