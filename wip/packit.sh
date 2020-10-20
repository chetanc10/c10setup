#!/bin/bash
# function compresses files/folders to common file formats

if [ -z "$1" ]; then
	# display usage if no parameters given
	echo -e "Usage: compress.sh <path/file_name> <zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
	exit 0
elif [ ! -e "$1" ]; then
	echo "'$1' - file/folder does not exist"
	exit 1
fi

case "$2" in
	tar.bz2)
		tar cvjf "$1.$2" ${1}                   ;;
	tar.gz)
		tar cvzf "$1.$2" ${1}                   ;;
	tar.xz)
		tar cvJf "$1.$2" ${1}                   ;;
	tar)
		tar cvf "$1.$2" ${1}                    ;;
	tbz2)
		tar cvjf "$1.$2" ${1}                   ;;
	tgz)
		tar cvzf "$1.$2" ${1}                   ;;
	rar)
		rar a "$1.$2" ${1}                      ;;
	zip)
		zip "$1.$2" ${1}                        ;;
	7z)
		7z x "$1.$2"                            ;;
	gz)
		gzip -k "$1.$2"                         ;;
	Z)
		compress "$1.$2"                        ;;
	lzma)
		lzma "$1.$2"                            ;;
	xz)
		xz "$1.$2"                              ;;
	bz2)
		bzip2 "$1.$2"                           ;;
	exe)
		cabextract "$1.$2"                      ;;
	*)
		echo "Bad Archive Type: '$2'"           ;;
esac

exit $?
