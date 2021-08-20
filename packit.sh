#!/bin/bash
# function compresses files/folders to common file formats

if [ -z "$1" ]; then
	# display usage if no parameters given
	echo -e "Usage: packit.sh <path/file_name> <tar.bz2|tar.gz|tar.xz|tar|tbz2|tgz|rar|zip|7z|gz|Z|lzma|xz|bz2>"
	exit 0
elif [ ! -e "$1" ]; then
	echo "'$1' - file/folder does not exist"
	exit 1
fi

case "$2" in
	tar.bz2)
		tar cvjf "$1.$2" ${1}          ;;
	tar.gz)
		tar cvzf "$1.$2" ${1}          ;;
	tar.xz)
		tar cvJf "$1.$2" ${1}          ;;
	tar)
		tar cvf "$1.$2" ${1}           ;;
	tbz2)
		tar cvjf "$1.$2" ${1}          ;;
	tgz)
		tar cvzf "$1.$2" ${1}          ;;
	rar)
		rar a "$1.$2" ${1}             ;;
	zip)
		zip -r "$1.$2" ${1}            ;;
	7z)
		7z a "$1.$2" ${1}              ;;
	gz)
		gzip -kr "$1"                  ;;
	Z)
		compress -v "$1"               ;;
	lzma)
		lzma -k "$1"                   ;;
	xz)
		xz -k "$1"                     ;;
	bz2)
		bzip2 -k "$1"                  ;;
	*)
		echo "Bad Archive Type: '$2'"  ;;
esac

exit $?
