#!/bin/bash

_print_pbar_usage () {
	echo "Usage: pbar.sh [arg1] [-v]
arg1:
    -h           - for help, (discards -v if given)
    name         - name of process to wait for completion
-v: optional, verbose mode"
	[ $1 -eq 1 ] && echo "Don't use time-taking-process && pbar.sh since time-taking-process might return non-zero and pbar.sh wouldn't be invoked in such case"
	exit -1
}

[ $# -gt 2 ] && _print_pbar_usage 0

[ "$1" == "-h" ] && _print_pbar_usage 1
[ "$1" == "-v" ] && _print_pbar_usage 0

([ $# -eq 2 ] && [ "$2" != "-v" ]) && _print_pbar_usage 0

if [ $# -eq 0 ]; then
# If no process name is given, we assume pbar.sh is invoked in a manner similar to:
# time-taking-process ; pbar.sh
	zenity --info --text "process from $name completed!" &
	paplay /usr/share/sounds/ubuntu/stereo/phone-incoming-call.ogg
	exit 0
fi

name=$1

FALSE=0
TRUE=1

if [ "$2" == "-v" ]; then
	ps aux | grep "$name" | grep -v grep | grep -v pbar.sh
else
	ps aux | grep "$name" | grep -v grep | grep -v pbar.sh > /dev/null
fi

terminated=$?
if [ "$terminated" == "$FALSE" ]; then
	echo -n "Shall I proceed to wait? [y|n]: "
	began_at=`date +%s`
	read yes
	if [ "$yes" != "y" ]; then
		exit 0
	fi
	echo "Going to wait now.."
	while [ 1 ]
	do
		ps aux | grep "$name" | grep -v grep | grep -v pbar.sh > /dev/null
		terminated=$?
		if [ "$terminated" == "$TRUE" ]; then
			break
		fi
		sleep 1
	done
	lapse=$((`date +%s` - $began_at))
	echo $lapse
	#notify-send "process from $name completed"
	zenity --info --text "process from $name completed.\nLapse: $lapse" 2>/dev/null &
	paplay /usr/share/sounds/ubuntu/stereo/phone-incoming-call.ogg &
else
	echo "$name: Process not found!"
fi

exit 0

