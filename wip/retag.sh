#!/bin/bash

UsageString="
This script can build cscope and ctags database 
1. abstracting advanced cscope/ctags usage 
2. easing inclusion/exclusion of files/directories

Usage: retag.sh <Options>

Options:
    -h              - displays this help message and exits (discards all other arguments)
    -t <filetypes>  - to include specific non-frequent file types as comma-list -with-no-spaces:
                      Expected arguments for -t: asm s html (more may be added later)
                      e.g. -t asm,html
                      All frequent file types get included by default and so not needed by -t:
                      c, cpp, h, hpp, asm, s, java
    -x <filenames>  - names of files/directories to exclude from cscope/ctags database build
                      For specific files with type-<EXT>ensions, give .<EXT> as in .java,.cpp
                      e.g. -x build,bin,x86,Documentation,tools,.java
    -xi <main/sub>  - name of directory to include exclusively, i.e., include just one folder
                      <sub> and exclude all other folder/files from <main>
    -k <platform>   - additional option for kernel retag, to skip writing lengthy argument list
                      because almost all the time while cscope/ctags operation with kernel will
                      require specific platform and avoiding some unwanted directories/files in
                      general. Use this generic option along with <platform> for quick retag
                      This is just a wrapper of -t,-x,-xi combo with all generic arguments.
                      Supported platforms - names of folders in arch/ from the kernel to retag
                      This is can be used as below:
                      e.g. -k arm64
                      This would be equivalent to:
                      -t asm,s -xi arch/arm64 -x Documentation,samples,tools,scripts,firmware
"

_print_retag_usage () {
	printf "$UsageString\n\n"
	exit $1
}

CTAGS_OPTS=""
CSCOPE_OPTS=""
FIND_OPTS=""
argx_opts=""
argxi_opts=""
k_opts=""
CSCOPE_FILES="./cscope.files"
CTAGS_FILES="./ctags.files"

# Parse the options
while [[ $# -gt 0 ]]; do
	opt="$1"
	case ${opt} in
		-h) _print_retag_usage 0 ;;
		#-t)
			#TagFileAppends=$1
			#shift ; shift # move past argument key and value
			#;;
		#-x)
			#shift; # move past argument key
			#excludes=${1}
			#file=$(echo $excludes | cut -d ','  -f1)
			#FIND_OPTS=" -path $file -prune"
			#excludes=$(echo $excludes | cut -d ',' -f2-)
			#for file in ${excludes//,/ }; do
				#FIND_OPTS="$FIND_OPTS -o -path $file -prune"
			#done
			#shift; # move past argument value
			#;;
		-k)
			shift; # move past argument key
			platform=${1}
			FIND_OPTS="-path \".git\" -prune"
			FIND_OPTS="$FIND_OPTS -o -path \"./tools/testing/selftests/powerpc\" -prune"
			excludes="Documentation,samples,scripts,firmware,fs,crypto,certs,sound,security"
			for file in ${excludes//,/ }; do
				FIND_OPTS="$FIND_OPTS -o -path \"./$file\" -prune"
			done
			for dir in "./arch"/* ; do
				[ "$(basename $dir)" == "$platform" ] && continue
				FIND_OPTS="$FIND_OPTS -o -path $dir -prune"
			done
			shift; # move past argument value
			;;
		*)
			echo "Invalid option: ${OPTARG}" 1>&2
			_print_retag_usage -1
			;;
	esac
done

# Now that all options are parsed, process them
if [ "${FIND_OPTS}" ]; then
	echo "find . \( ${FIND_OPTS} \) -o -name *.[ch] -print > $CSCOPE_FILES" > /tmp/fscope.sh
	chmod +x /tmp/fscope.sh && /tmp/fscope.sh
	sed "s/\"//g" $CSCOPE_FILES > $CTAGS_FILES
	CSCOPE_OPTS="-Rb -k -i $CSCOPE_FILES"
	CTAGS_OPTS="-L $CTAGS_FILES"
else
	echo "None $FIND_OPTS"
	CSCOPE_OPTS="-Rb"
	CTAGS_OPTS="-R"
fi

rm -rf cscope.out tags
ctags $CTAGS_OPTS &
cscope $CSCOPE_OPTS 
while true; do pgrep "ctags" > /dev/null && sleep 1 || break; done

exit 0
