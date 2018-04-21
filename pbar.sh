#!/bin/bash

name=$1

# If no process name is given, we assume pbar.sh is invoked in a manner similar to:
# time-taking-process ; pbar.sh
#
# Don't use time-taking-process && pbar.sh since time-taking-process might return non-zero
# and pbar.sh wouldn't be invoked in such case
if [ "$name" == "" ]; then
	#echo "Usage: pbar.sh <process name>"
	#echo "process name should be as is given in cmd in terminal"
	#exit -1
	zenity --info --text "process from $name completed!" &
	paplay /usr/share/sounds/ubuntu/stereo/phone-incoming-call.ogg
	exit 0
fi

FALSE=0
TRUE=1

pgrep $name > /dev/null

if [ "$2" == "-v" ]; then
	ps aux | grep "$name" | grep -v grep | grep -v pbar.sh
else
	ps aux | grep "$name" | grep -v grep | grep -v pbar.sh > /dev/null
fi

terminated=$?
if [ "$terminated" == "$FALSE" ]; then
	echo -n "Shall I proceed to wait? [y|n]: "
	read yes
	if [ "$yes" != "y" ]; then
		exit 0
	fi
	echo "Going to wait now.."
	while [ 1 ]
	do
		ps aux | grep "$name" | grep -v grep | grep -v pbar.sh > /dev/null
		#pgrep $name > /dev/null
		terminated=$?
		if [ "$terminated" == "$TRUE" ]; then
			break
		fi
		sleep 1
	done
	#notify-send "process from $name completed"
	zenity --info --text "process from $name completed!" &
	paplay /usr/share/sounds/ubuntu/stereo/phone-incoming-call.ogg &
else
	echo "$name: Process not found!"
fi

exit 0

