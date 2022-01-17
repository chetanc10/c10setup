#!/bin/bash

gUsageString="
This script can build cscope and ctags database 
1. abstracting advanced cscope/ctags usage 
2. easing inclusion/exclusion of files/directories

Usage: retag.sh <Options>

Options:
    -h              - displays this help message & exits (discards other args)
	 -v              - verbose output (print time taken & size of DB files)
    -x <filenames>  - names of files/directories to exclude from cscope/ctags
                      database build.
                      For specific files with type-<EXT>ensions, give .<EXT>
                      as in .java,.cpp
                      e.g. -x build,bin,x86,Documentation,tools,.java
    -xi <main/sub>  - name of directory to include exclusively, i.e., include
                      just one folder <sub> & exclude all other folder/files
                      from <main>
    -k <platform>   - kernel specific option, to skip lengthy args list
                      because mostly cscope/ctags with kernel requires
                      specific platform and avoid unwanted directories/files in
                      general. Use this option along with <platform> for quick
                      retag. This just wraps -t,-x,-xi combo in general.
                      Supported platforms - folders in arch/ kernel source
                      This is can be used as below:
                      e.g. -k arm64
                      which is equivalent to:
                      -t asm,s -xi arch/arm64 \
								 -x Documentation,samples,tools,scripts,firmware
NOTE:
1. With no options, user can just create a .excludes file in current directory
   with each line pointing to a file or directory as relative paths.
   e.g. contents in .excludes
	./fs/ext4
	./examples
2. -k, -x, -xi options are needed only once, as it creates a .excludes file 
   once and next time $0 is run, it reads .excludes and lists to-exclude-files
"
#-t <filetypes>  - include specific infrequent file types as a comma list 
#with no spaces:
#Expected args: asm s html (more may be added later)
#e.g. -t asm,html
#Frequent file types get included by default & 
#not needed by -t: c, cpp, h, hpp, asm, s, java

_print_retag_usage () {
	printf "$gUsageString\n\n"
	exit $1
}

ktag=""
gXFile="${PWD}/.excludes"
gVerbose=0
CscopeOpts="-Rb"
CtagsOpts="-R"
FindOpts=""
CscopeFile="./cscope.files"
CtagsFile="./ctags.files"

gIncDir=""

gExcludes=()

_AddToExcludesFn ()
{
	files=${@}
	for file in ${files[@]}; do
		[ -n "$gIncDir" ] && [ "$(basename $file)" == "$gIncDir" ] && continue
		gExcludes+=(./${file})
	done
}

AddToExcludesFn ()
{
	gIncDir=""
	if [ "$1" == "list" ]; then
		shift 1
		for fld in ${@}; do
			[ -f ${fld} ] && _AddToExcludesFn ${fld} && continue
			[ -d ${fld} ] && flist="${fld}"/*; _AddToExcludesFn ${flist[@]}
		done
		_AddToExcludesFn ${files[@]}
	elif [ "$1" == "direx" ]; then
		[ ! -d $3/$2 ] && echo "ERROR: $3/$2 doesn't exist!" && exit -2
		gIncDir=${2}
		files="${3}"/*
		_AddToExcludesFn ${files[@]}
	fi
}

LoadExcludesFromExFileFn ()
{
	[ ! -e ${gXFile} ] && return
	gExcludes=()
	while true; do
		read -r file <&3
		[ -z ${file} ] && break
		[ ! -e ${file} ] && continue
		gExcludes+=(${file})
	done 3<${gXFile}
}

SaveExcludesToExFileFn ()
{
	rm -rf ${gXFile}; touch ${gXFile}
	for file in ${gExcludes[@]}; do
		echo ${file} >> ${gXFile}
	done
}

t0=$SECONDS

# Parse the options
while [[ $# -gt 0 ]]; do
	opt="$1"
	case ${opt} in
		-h) _print_retag_usage 0
			;;
		-v) gVerbose=1
			shift 1
			;;
		-x) AddToExcludesFn list ${2//,/ }
			SaveExcludesToExFileFn
			shift 2; # move past argument key and value
			;;
		-xi) AddToExcludesFn direx $(basename ${2}) $(dirname ${2})
			SaveExcludesToExFileFn
			shift 2; # move past argument key and value
			;;
		-k)
			# If kernel-exclude-listing-file is absent, 
			# create default plus ./arch/excludes
			if [ ! -f ${gXFile} ]; then
				gExcludes=(./certs ./crypto ./Documentation ./drivers/gpu \
					./firmware ./fs ./LICENSES ./samples ./scripts ./security \
					./sound ./tools/testing/selftests/powerpc)
				# Add arch excludes to list
				AddToExcludesFn direx $2 "./arch"
				SaveExcludesToExFileFn
				echo "Excluding rarely/never visited kernel source directories: "
				cat ${gXFile}
				# allow user to add or remove files/directories in the file
				read -p "Want to add/remove dir-names in excludes? (y|n): " ok
				[ "$ok" == "y" ] && \
					read -p "Open ${gXFile}, edit and save and press <ENTER>: " ok
			fi
			shift 2; # move past argument key and value
			ktag="-k"
			;;
		*)
			echo "Invalid or not-supported-yet option: ${OPTARG}" 1>&2
			_print_retag_usage -1
			;;
	esac
done

# Get gXFile contents into a bash listing-variable
LoadExcludesFromExFileFn

if [ "${gExcludes}" ]; then
	[ $gVerbose == 1 ] && \
		echo -e "\n------ Excluding following files from cscope/ctags build:"
	FindOpts="-path \"./.git\" -prune"
	for file in ${gExcludes[@]}; do
		[ $gVerbose == 1 ] && echo "$file"
		FindOpts="${FindOpts} -o -path \"${file}\" -prune"
	done
	[ $gVerbose == 1 ] && echo -e "------\n"
fi

# Now that all options are parsed, process them
if [ "${FindOpts}" ]; then
	fscope="/tmp/fscope.sh"
	echo "find . \( ${FindOpts} \) -o -name *.[ch] -print > $CscopeFile" > ${fscope}
	chmod +x ${fscope} && ${fscope} #&& rm -rf ${fscope}
	sed "s/\"//g" $CscopeFile > $CtagsFile
	CscopeOpts="-Rb $ktag -i $CscopeFile"
	CtagsOpts="-L $CtagsFile"
fi

#rm -rf cscope.out tags
ctags $CtagsOpts &
cscope $CscopeOpts 
while true; do pgrep "ctags" > /dev/null && sleep 1 || break; done

if [ $gVerbose == 1 ]; then
	tdiff=$(($SECONDS-$t0))
	printf "\nDB build duration (mm:ss) : $(($tdiff/60)):$(($tdiff%60))\n"
	dbfiles=(tags cscope.out ncscope.out ctags.files cscope.files)
	dbsz=0
	for file in ${dbfiles[@]}; do
		[ ! -f ${file} ] && continue
		fsz=$(du -hb ${file} | awk '{print $1}')
		printf "%-26s: $fsz Bytes\n" "${file} DB size"
		dbsz=$((dbsz+$fsz))
	done
	printf "%-26s: ${dbsz} Bytes\n\n" "Total DB size"
fi	

exit 0
