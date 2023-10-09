#!/bin/bash

Usage="Usage: stacker.sh <src-directory> [src-dir/sub-dir]"

[[ -z "$1" ]] && echo $Usage && exit -1

tel=/home/$USER/Music/mixtel
hin=/home/$USER/Music/mixhin
eng=/home/$USER/Music/mixeng
oth=/home/$USER/Music/mixoth
sou=/home/$USER/Music/mixsouth

echo "For stacking choices:
	RET : do nothing and proceed to next entry
	d   : remove the current file
	t   : move the current file to directory" $tel"
	h   : move the current file to directory" $hin"
	e   : move the current file to directory" $eng"
	o   : move the current file to directory" $oth"
	s   : move the current file to directory" $sou"
	x|q : exit the utility right now!
	"

mkdir -p $tel
mkdir -p $hin
mkdir -p $eng
mkdir -p $oth
mkdir -p $sou

[[ "$2" == */ ]] && offset_dir=${2::-1} || offset_dir="$2"
[[ "$1" == */ ]] && main_dir=${1::-1} || main_dir="$1"

[ ! -d "$1" ] && echo "invalid path: $1" && exit -1
[ -n "$2" ] && [ ! -d "$2" ] && echo "invalid path: $2" && exit -2

take_action () {
	retval=1
	case "$1" in
		d) rm -rf "$2"
			;;
		t) mv "$2" $tel/
			;;
		h) mv "$2" $hin/
			;;
		e) mv "$2" $eng/
			;;
		o) mv "$2" $oth/
			;;
		o) mv "$2" $sou/
			;;
		x|q) echo "Exiting.." >&2 ; retval=-1
			;;
		*) retval=0
			;;
	esac
	echo $retval
}

rem_check () {
	if [ $(ls -A "$1" | wc -l) -eq 0 ]; then
		echo -n "Remove emptied dir $1? (y|n): " >&2
		read answer
		[ "$answer" == "y" ] && rmdir "$1"
		echo 1
	else
		echo 0
	fi
}

ask_stack () {
	echo -n "Wanna stack $1? (y|q|RET): "
	read answer
	[ "$answer" == "y" ] && \
		[ $(rem_check "$1") -eq 0 ] && stacker "$1"
	[ "$answer" == "q" -o "$answer" == "x" ] && echo "Exiting.." && exit 0
}

stacker () {
	local entry
	local rets
	for entry in "$1"/*
	do
		if [ -d "$entry" ]; then
			# if user has given an offset directory, we skip all entries
			# till we find that offset directory..
			# if user didn't ask for offset_dir, we just stack that as usual
			if [ -n "$offset_dir" ]; then
				# if offset_dir found?
				if [ "$entry" == "$offset_dir" ]; then
					if [ $(rem_check "$entry") -eq 0 ]; then
						stacker "$entry"
					fi
					offset_dir=""
				else
					# for sub-dirs inside $2 directory
					parent_dir=$(dirname "$entry")
					[ "$parent_dir" == "$offset_dir" ] && ask_stack "$entry"
				fi
			elif [ -z "$offset_dir" ]; then
				ask_stack "$entry"
			fi
			continue
		fi
		cvlc "$entry" 1>/dev/null 2>/dev/null &
		echo -n "'$entry' Choice: "
		read answer
		pkill vlc
		rets=$(take_action $answer "$entry")
		[ $rets -eq -1 ] && exit 0
	done
	rets=$(rem_check "$1")
	if [ $rets -eq 0 ] && [ $(ls -A "$1" | wc -l) -eq 1 ]; then
		local singly="$1/$(ls "$1" | sort -n | head -1)"
		echo -n "Just 1 entry left in $1. Move it to tel|hin|eng|oth or nothing? (t|h|e|o|RET): "
		read answer
		moved=$(take_action "$answer" "$singly")
		[ $moved -eq 1 ] && rets=$(rem_check "$1")
	fi
	return 0
}

stacker "$main_dir" "$offset_dir" && echo "stacker is done!"

#shopt -s nullglob dotglob     # To include hidden files

if [ `ls -A $tel | wc -l` -eq 0 ]; then
	#echo "Removing empty directory: $tel";
	rm -rf $tel
fi

if [ `ls -A $hin | wc -l` -eq 0 ]; then
	#echo "Removing empty directory: $hin";
	rm -rf $hin
fi

if [ `ls -A $eng | wc -l` -eq 0 ]; then
	#echo "Removing empty directory: $eng";
	rm -rf $eng
fi

if [ `ls -A $oth | wc -l` -eq 0 ]; then
	#echo "Removing empty directory: $oth";
	rm -rf $oth
fi

if [ `ls -A $sou | wc -l` -eq 0 ]; then
	#echo "Removing empty directory: $sou";
	rm -rf $sou
fi

