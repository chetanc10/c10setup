#!/bin/bash

git status > gout
cp gout jout
sed -i '/modified:/!d' jout
cut -f3- -d" " jout > jout1
mv jout1 jout

while true
do
	read -r file <&3
	echo "modified: $file"
	clear
	git diff $file
	echo -ne "Want to revert? (y|n|x): "
	read _choice <&0
	[ "$_choice" == "n" ] && continue
	[ "$_choice" == "x" ] && break
	git checkout $file
done 3<jout

exit 0
