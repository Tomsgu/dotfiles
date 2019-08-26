#!/bin/bash

# Setup workspaces.
workspace 1 output eDP-1

#setup displays
xrandr --output DP-1 --off 
xrandr --output HDMI-2 --off
xrandr --output eDP-1 --primary --mode 2560x1440 --pos 0x0
xrandr --dpi 180
