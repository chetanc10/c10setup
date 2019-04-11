#!/bin/bash
#Media medren

Usage="Usage: medren.sh <src-directory>"

[[ -z "$1" ]] && echo $Usage && exit -1

search_dir=$@
[ ! -d "$1" ] && echo "'$search_dir' is not a valid directory!" && exit -1

declare -a rcmd_names=("despace" "desquare" "deparenthesise" "dedash")

declare -A rcmd_usage=(["despace"]="Replace all occurrences of ' '(space) with '_'(underscore)" ["desquare"]="Remove all occurrences of '[anything-between]'" ["deparenthesise"]="Remove all occurrences of '(anything-between)" ["dedash"]="Replace all occurrences of '_-_' with '_'")

declare -A rcmd=(["despace"]="s/ /_/g" ["desquare"]="s/\[.*\]//g" ["deparenthesise"]="s/\(.*\)//g" ["dedash"]="s/_-_/_/g")

medren () {
	substituter="${rcmd["$2"]}"
	echo "Folder: $1"
	cd "$1"
	local entry
	for entry in ./*
do
	[[ -d "$entry" ]] && [[ "$entry" != "." ]] && medren "$entry" $2
	#rename -n "$substituter" "$entry"
	rename "$substituter" "$entry"
done
	#echo "going back"
	[ "$1" != "." ] && [ "$1" != ".." ] && cd ..
}

for rcmd_entry in "${rcmd_names[@]}"
do
	echo -e "\n$rcmd_entry: ${rcmd_usage["$rcmd_entry"]}"
	echo -ne "Want to $rcmd_entry?(y|n): "
	read answer
	[[ "$answer" == "y" ]] && medren "$search_dir" $rcmd_entry && echo "$rcmd_entry operation is done!"
done

echo -ne "\n"

exit 0

