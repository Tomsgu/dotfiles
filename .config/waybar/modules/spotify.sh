#!/bin/sh

status=$(playerctl metadata --player=spotify --format '{{lc(status)}}')

if [[ $status == "playing" ]]; then
    playing=$(playerctl metadata --player=spotify --format '{{artist}} - {{title}}')
    if [[ ${#playing} > 40 ]]; then
        playing=$(echo $playing | cut -c1-40)"..."
    fi
elif [[ $status == "paused" ]]; then
    playing=""
elif [[ $status == "stopped" ]]; then
    playing=""
fi

echo -e "{\"text\":\"" $playing"\", \"class\":\""$status"\"}"
