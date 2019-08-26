#!/bin/bash

# Parse json string with jq utility. 
# Print output name to the var.
outputs=($(swaymsg -rt get_outputs | jq -r '.[] | .name'))

# Get length of outputs.
length="${#outputs[@]}"

if [ ${length} -gt 1 ]
then
    swaymsg output DP-1 resolution 1920x1080 pos 0 0
    swaymsg output HDMI-A-2 resolution 1680x1050 position 1920 0
    swaymsg output eDP-1 disable
else
    swaymsg output eDP-1 enable
    swaymsg output eDP-1 resolution 2560x1440 scale 2 position 0 0
fi
