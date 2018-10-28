#!/bin/bash
xkill -id `xprop -root _NET_ACTIVE_WINDOW | cut -d\# -f2`
