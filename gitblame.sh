#!/bin/bash

[ $# -eq 0 ] && \
	echo "Usage: $0 <filename[with-optional-path]>" && \
	exit -1

file="${@}"
abspfile="$(realpath ${file})"
filename=$(basename ${abspfile})
filepath=$(dirname ${abspfile})

echo "---------------------" > /tmp/gbl
echo "File as per CWD: ${file}" >> /tmp/gbl
echo "Absolute path  : ${filepath}/${filename}" >> /tmp/gbl
echo -e "---------------------\n" >> /tmp/gbl

cd "${filepath}"

git blame "${filename}" >> /tmp/gbl
st=$?
if [ $st -ne 0 ]; then
	echo "ERR: ${file} not part of a git project!"
elif [ -z $VIMRUNTIME ]; then
	vim /tmp/gbl
fi
exit $st

