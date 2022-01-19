#!/bin/bash

git status > ModifiedFilesList || exit -1
sed -i '/modified:/!d' ModifiedFilesList

if [ $(wc -l ModifiedFilesList | awk '{print $1}') -eq 0 ]; then
	echo "No local file modifications found in this git repo"
	rm -rf ModifiedFilesList
	exit 0
fi

while read -r file <&3; do
	file=$(echo ${file}| awk '{print $2}')
	clear -x && echo "***********Modified: ${file}"
	read -p "Choose u(undo diff) | n(do nothing) | d(view diff) | x(exit): " op
	if [ "$op" == "d" ]; then
		git diff ${file} > /tmp/fdiff.patch
		echo "Opening diff file /tmp/fdiff.patch with Vim ..."; sleep 1
		vim -R /tmp/fdiff.patch
		read -p "Undo changes in ${file}? (y|n|x): " op
		[ "$op" == "y" ] && git checkout ${file}
	fi
	[ "$op" == "x" ] && break
done 3<ModifiedFilesList

rm -rf ModifiedFilesList

exit 0
