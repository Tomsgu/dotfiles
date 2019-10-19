#!/usr/bin/env  sh

killall -q waybar

# Wait until the processes have been shut up.
while pgrep -x waybar > /dev/null; do sleep 1; done

waybar
