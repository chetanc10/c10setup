#!/bin/bash

# I'm here to help generate tags & cscope database for a given path with include/exclude options
# As of now, only .c and .h files are supported
# More options shall come -TODO

_print_retag_usage () {
	echo "Usage: retag.sh <arg1> [xtra_opts]
arg1:
    -h           - for help, (discards all other arguments)
    -i           - to build ctags and cscope database with specific source file types (.c, .h, .cpp, etc)"
	[ "$1" == "-h" ] && exit 0
	exit -1
}

CTAGS_OPTS=""
CSCOPE_OPTS=""
FIND_OPTS=""
CSCOPE_FILES="./cscope.files"
CTAGS_FILES="./ctags.files"

NO=0
YES=1

_await_retag_completion () {
	while [ 1 ]
	do
		pgrep "ctags" || pgrep "cscope" > /dev/null
		_done=$?
		[ "$_done" == "$YES" ] && break
		sleep 1
	done
}

if 0; then
	### New approach WIP ###
	# Parse the options
	while getopts ":hix" opt; do
		case ${opt} in
			h)
				_print_retag_usage "${opt}"
				;;
			i)
				FIND_OPTS="\("
				inc_ftypes=${OPTARG}
				for ftype ${inc_ftypes//,/ }; do
					case $ftype in
						c|h|cpp|java|asm)
							FIND_OPTS="$FIND_OPTS -iname \*.$ftype"
							;;
						*)
							echo "Skipping invalid file format: $ftype"
							continue
							;;
					esac
				done
				FIND_OPTS="$FIND_OPTS \)"
				;;
			x)
				exc_dirs=${OPTARG}
				for dir in ${exc_dirs//,/ }; do
					FIND_OPTS="$FIND_OPTS -not \( -path $dir -prune \)"
				done
				;;
			\?)
				echo "Invalid option: ${OPTARG}" 1>&2
				_print_retag_usage "${opt}"
				;;
		esac
	done; shift $((OPTIND-1))
	# Now that all options are parsed, process them
	if [ $FIND_OPTS ]; then
		find . ${FIND_OPTS} -exec echo '"{}" ' \; > $CSCOPE_FILES
		sed "s/\"//g" $CSCOPE_FILES > $CTAGS_FILES
		CSCOPE_OPTS="-Rb -i $CSCOPE_FILES"
		CTAGS_OPTS="-L $CTAGS_FILES"
	else
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
