#!/bin/bash

Usage="This renamer script is used to rename files in a given directory;\n
Renames files containing a specific pattern with a user-given pattern\n
Usage: ren.sh \"<target>\" <old-substring> <new-substring>\n
Target MUST be an existing directory name enclosed in \"\",\n
just in case the target name could contain special characters and spaces\n"

[ -z "$1" ] && echo -e $Usage && exit -1

([ -z $2 ] || [ -z $3 ]) && \
	echo "ERROR: Need both old and new substrings to rename file name(s)" && \
	exit -2

oldstr=$2
newstr=$3

[ ! -d "$1" ] && echo "'$1' is not a valid directory!" && exit -3

cd "$1"
for file in ./*
do
	[ -d "$file" ] && \
		echo "Skipping directory $file (Recursion not supported yet)" && \
		continue
	rename "s/$oldstr/$newstr/g" "$file" && echo "Renamed $file" || \
		(echo "Rename failed on $file" && exit -4)
done

echo -ne "\n"

exit 0

