#!/bin/bash
# function Extract for common file formats

if [ -z "$1" ]; then
	# display usage if no parameters given
	echo -e "Usage: extract.sh <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz> [new]\n\t[new] is optional, and indicates the script to create a directory first and call for extraction"
	exit 0
elif [ ! -f "$1" ]; then
	echo "'$1' - file does not exist"
	exit 1
elif [ "$2" ]; then
	[ $2 != "new" ] && echo "2nd argument MUST either be 'new' (new to indicate) or EMPTY" && exit 2
	CreateNewDir=1
else
	CreateNewDir=0
fi

SetDir ()
{
	# If new directory to be created, then create one 
	[ $CreateNewDir == 0 ] && gDir="" && return 1
	gDir=${1%.$2}
	mkdir ${gDir} || exit 3
	return 0
}

case "$1" in
	*.tar.bz2)
		SetDir $1 tar.bz2 && xops="-C ${gDir}"
		tar xvjf "$1" ${xops}                   ;;
	*.tar.gz)
		SetDir $1 tar.gz && xops="-C ${gDir}"
		tar xvzf "$1" ${xops}                   ;;
	*.tar.xz)
		SetDir $1 tar.xz && xops="-C ${gDir}"
		tar xvJf "$1" ${xops}                   ;;
	*.tar)
		SetDir $1 tar && xops="-C ${gDir}"
		tar xvf "$1" ${xops}                    ;;
	*.tbz2)
		SetDir $1 tbz2 && xops="-C ${gDir}"
		tar xvjf "$1" ${xops}                   ;;
	*.tgz)
		SetDir $1 tgz && xops="-C ${gDir}"
		tar xvzf "$1" ${xops}                   ;;
	*.rar)
		SetDir $1 rar
		unrar x "$1" ${gDir}                    ;;
	*.zip)
		SetDir $1 zip && xops="-d ${gDir}"
		unzip "$1" ${xops}                      ;;
	*.7z)
		SetDir $1 7z
		if [ "${gDir}" ]; then
			cd ${gDir} && 7z x ../"$1"
		else
			7z x "$1"
		fi
		;;
	*.gz)
		gunzip -k "$1"                          ;;
	*.Z)
		uncompress "$1"                         ;;
	*.lzma)
		unlzma "$1"                             ;;
	*.xz)
		unxz "$1"                               ;;
	*.bz2)
		bunzip2 "$1"                            ;;
	*.exe)
		cabextract "$1"                         ;;
	*)
		echo "Bad Archive Type: '$1'"           ;;
esac

exit $?
