#!/bin/bash

while true; do
	BatteryStatus=$(cat /sys/class/power_supply/BAT1/status)
	[ $BatteryStatus != "Discharging" ] && break
	sleep 10
done
zenity --info --text="BATTERY IS NOW CHARGING.. YAY!" 2>/dev/null &
paplay /usr/share/sounds/freedesktop/stereo/phone-incoming-call.oga
