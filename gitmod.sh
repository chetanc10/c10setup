#!/bin/bash

git status > ModifiedFilesList || exit -1
sed -i '/modified:/!d' ModifiedFilesList

if [ $(wc -l ModifiedFilesList | awk '{print $1}') -eq 0 ]; then
	echo "No local file modifications found in this git repo"
	rm -rf ModifiedFilesList
	exit 0
fi

ChooseActionFn ()
{
	file="${@}"
	# Ensure user chooses a valid action
	while true; do
		clear -x && echo "***********Modified: ${file}"
		read -p "Choose r(revert) | s(skip) | v(view diff) | x(exit): " op
		case $op in
			s) break ;;
			r) git checkout "${file}"; break ;;
			x) rm -rf ModifiedFilesList; exit 0 ;;
			v) git diff "${file}" > /tmp/fdiff.patch
				echo "Opening diff file of ${file} with Vim ..."; sleep 1
				vim -R /tmp/fdiff.patch
		esac
	done
}

while read -r file <&3; do
	ChooseActionFn "$(echo ${file} | awk '{print $2}')"
done 3<ModifiedFilesList

rm -rf ModifiedFilesList

exit 0
