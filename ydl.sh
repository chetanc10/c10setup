#!/bin/bash

url=$(yad --width=1024 --title="Youtube-Downloader" \
	--entry --text="Enter Youtube URL here" \
	--button="audio":0 --button="video":2 --button="Cancel":3)
option=$?

declare -A ydlToolOpts=(["0"]=" --audio-format mp3 -x " ["2"]="")
case $option in
	0|2)
		if [ -z "${url}" ]; then
			yad --error --title="ERROR" \
				--text="Need Youtube URL to download Video/Audio"
			exit -1
		fi
		ydlOpt=${ydlToolOpts[$option]}
		;;
	3|*)
		exit 0
		;;
esac

gnome-terminal -- bash -c \
	"cd ~/Downloads; youtube-dl ${ydlOpt} \"${url}\"; read -p 'Press ENTER..'"

