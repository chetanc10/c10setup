#!/bin/bash
# function Extract for common file formats

if [ -z "$1" ]; then
	# display usage if no parameters given
	echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
	exit 0
elif [ ! -f "$1" ]; then
	echo "'$1' - file does not exist"
	exit 1
fi

SetDir ()
{
	gDir=${1%.$2}
	mkdir ${gDir} && echo ${gDir} || exit 2
}

case "$1" in
	*.tar.bz2)
		SetDir $1 tar.bz2
		tar xvjf "$1" -C ${gDir}      ;;
	*.tar.gz)
		SetDir $1 tar.gz
		tar xvzf "$1" -C ${gDir}      ;;
	*.tar.xz)
		SetDir $1 tar.xz
		tar xvJf "$1" -C ${gDir}      ;;
	*.tar)
		SetDir $1 tar
		tar xvf "$1" -C ${gDir}       ;;
	*.tbz2)
		SetDir $1 tbz2
		tar xvjf "$1" -C ${gDir}      ;;
	*.tgz)
		SetDir $1 tgz
		tar xvzf "$1" -C ${gDir}      ;;
	*.rar)
		SetDir $1 rar
		unrar x "$1" ${gDir}          ;;
	*.zip)
		SetDir $1 zip
		unzip "$1" -d ${gDir}         ;;
	*.7z)
		SetDir $1 7z
		cd ${gDir} && 7z x ../"$1"    ;;
	*.gz)
		gunzip -k "$1"                ;;
	*.Z)
		uncompress "$1"               ;;
	*.lzma)
		unlzma "$1"                   ;;
	*.xz)
		unxz "$1"                     ;;
	*.bz2)
		bunzip2 "$1"                  ;;
	*.exe)
		cabextract "$1"               ;;
	*)
		echo "Bad Archive Type: '$1'" ;;
esac

exit $?
