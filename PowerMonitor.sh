#!/bin/bash

[ ! -f /sys/class/power_supply/BAT1/capacity ] && exit 0

CurrentCharge=$(cat /sys/class/power_supply/BAT1/capacity)

#echo -e "Current Charge: $CurrentCharge"

CriticalLevel=20

if [ $CurrentCharge -le $CriticalLevel ]; then
	IsCharging=$(cat /sys/class/power_supply/BAT1/status)
	if [ $IsCharging == "Discharging" ]; then
		kill `pgrep zenity`
		export DISPLAY=:0.0
		zenity --info --text="***** BATTERY POWER CRITICALLY LOW ($CurrentCharge%): CONNECT TO CHARGER ****" 2>/dev/null
		#touch /home/chetan/ChetaN/junk/scrap/$(date +%T)
	fi
fi

