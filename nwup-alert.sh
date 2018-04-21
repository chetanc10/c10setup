#!/bin/bash

nwif=$1
[ -z "$nwif" ] && echo "Usage: nwup-alert.sh <ethN | wlanN> where N is >=0" && exit -1

ping -q -I $nwif google.com -c 1 1>/dev/null
[ $? -eq 2 ] && echo "$nwif failed here" && exit -2

while [ $? -ne 0 ]
do
	sleep 2
	ping -q -I $nwif google.com -c 1 1>/dev/null
done

zenity --info --text="$nwif is up" &
paplay /usr/share/sounds/freedesktop/stereo/phone-incoming-call.oga
paplay /usr/share/sounds/freedesktop/stereo/phone-incoming-call.oga

exit 0

