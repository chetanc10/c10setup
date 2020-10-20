#!/bin/bash

# I'm here to help generate tags & cscope database for a given path with include/exclude options
# As of now, only .c and .h files are supported
# More options shall come -TODO

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
	[ "$1" == "-h" ] && printf "$UsageString\n\n" && exit 0
	exit -1
}

CTAGS_OPTS=""
CSCOPE_OPTS=""
FIND_OPTS=""
argx_opts=""
argxi_opts=""
k_opts=""
CSCOPE_FILES="./cscope.files"
CTAGS_FILES="./ctags.files"

NO=0
YES=1

_await_retag_completion () {
	while [ 1 ]; do
		pgrep "ctags" > /dev/null || pgrep "cscope" > /dev/null
		_done=$?
		[ "$_done" == "$YES" ] && break
		sleep 1
	done
}

if true; then
	### New approach WIP ###
	# Parse the options
	while [[ $# -gt 0 ]]; do
		opt="$1"
		case ${opt} in
			-h)
				_print_retag_usage -h
				;;
			-t)
				echo "-t: Not supported yet"
				shift
				TagFileAppends=$1
				shift
				exit 0
				;;
			-x)
				shift; # move on to next bash argument
				excludes=${1}
				file=$(echo $excludes | cut -d ','  -f1)
				FIND_OPTS=" -path $file -prune"
				excludes=$(echo $excludes | cut -d ',' -f2-)
				for file in ${excludes//,/ }; do
					FIND_OPTS="$FIND_OPTS -o -path $file -prune"
				done
				shift; # move on to next bash argument
				;;
			-k)
				shift; # move on to next bash argument
				platform=${1}
				echo "platform: ${platform}"
				FIND_OPTS="-path \"./arch/*\" ! -path \"./arch/$platform*\" -prune"
				excludes="Documentation,samples,scripts,firmware,fs,crypto,certs,sound,security"
				for file in ${excludes//,/ }; do
					FIND_OPTS="$FIND_OPTS -o -path \"./$file\" -prune"
				done
				shift; # move on to next bash argument
				;;
			*)
				echo "Invalid option: ${OPTARG}" 1>&2
				_print_retag_usage "${opt}"
				;;
		esac
	done
	# Now that all options are parsed, process them
	if [ "${FIND_OPTS}" ]; then
		echo "Find-options: $FIND_OPTS"
		find . ${FIND_OPTS} -o -name "*.c" > $CSCOPE_FILES
		sed "s/\"//g" $CSCOPE_FILES > $CTAGS_FILES
		read -p "okay this.." ok
		CSCOPE_OPTS="-Rb -i $CSCOPE_FILES"
		CTAGS_OPTS="-L $CTAGS_FILES"
	else
		echo "None $FIND_OPTS"
		CSCOPE_OPTS="-Rb"
		CTAGS_OPTS="-R"
	fi

else
	### Old approach tested ###
	if [ "$1" == "-i" ]; then
		find . \( -iname "*.c" -or -iname "*.h" \) -exec echo '"{}" ' \; > $CSCOPE_FILES
		find . \( -iname "*.c" -or -iname "*.h" \) > $CTAGS_FILES
		if [ ! -s $CSCOPE_FILES ]; then
			echo "No .c | .h files found!"
			rm -rf $CSCOPE_FILES
			exit -1
		fi
		CSCOPE_OPTS="-Rb -i $CSCOPE_FILES"
		CTAGS_OPTS="-L $CTAGS_FILES"
	else
		CSCOPE_OPTS="-Rb"
		CTAGS_OPTS="-R"
	fi

fi

ctags $CTAGS_OPTS &
cscope $CSCOPE_OPTS &

_await_retag_completion
exit 0
