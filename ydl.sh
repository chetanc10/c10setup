#!/bin/bash

url=$(yad --width=1024 --title="Youtube-Downloader" \
	--entry --text="Enter Youtube Video URL here" \
	--button="audio":0 --button="video":2 --button="Cancel":3)
option=$?

declare -A ydlToolOpts=(["0"]=" --audio-format mp3 -x " ["2"]="")
case $option in
	0|2)
		if [ -z "${url}" ]; then
			yad --error --title="ERROR" -- "Need Youtube URL to download Video/Audio"
			exit -1
		fi
		YTD_OPT=${ydlToolOpts[$option]}
		;;
	3|*)
		exit 0
		;;
esac

gnome-terminal -- bash -c "cd ~/Downloads; youtube-dl ${YTD_OPT} \"${url}\"; read -p 'Press ENTER..'"

