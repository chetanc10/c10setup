#!/bin/bash

ch=""

HandleThisFileFn ()
{
	file=${1}
	read -p "Select - u(undo changes) | n(nothing) | d(diff) | x(exit) : " ch
	if [ "$ch" == "d" ]; then
		git diff ${file} > /tmp/fdiff.patch
		echo "Opening diff file /tmp/fdiff.patch with Vim ..." ; sleep 1
		vim -R /tmp/fdiff.patch
		read -p "Undo changes in ${file}? (y|n|x): " ch
		[ "$ch" == "y" ] && ch="u"
	fi
	[ "$ch" == "u" ] && git checkout ${file}
}

git status > gout
cp gout jout
sed -i '/modified:/!d' jout

while true; do
	read -r file <&3
	[ -z "${file}" ] && break
	file=$(echo ${file}| awk '{print $2}')
	clear -x && echo "***********Modified: ${file}"
	HandleThisFileFn ${file}
	[ "$ch" == "x" ] && break
done 3<jout

rm -rf jout

exit 0
