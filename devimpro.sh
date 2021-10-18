#!/bin/bash

gUsageString="
Usage: devimpro.sh <option>
Options:
-i <file>             - Indent a file
-I <dir>              - Indent all files in a directory
-r <file> <old> <new> - Replace old string with new string in a file
-R <dir> <old> <new>  - Replace old string with new string in all files in a directory
-l <file> <print-fn>  - Replace a print-function interactively with syslog with LOG levels in a file
-L <dir> <print-fn>   - Replace a print-function interactively with syslog with LOG levels in all files in a directory

NOTES:
<file> - this is actually absolute/relative path of a file
<dir> - this is actually absolute/relative path of a directory to operate recursively
"

DisplayUsageFn ()
{
	st=$1
	shift
	[ $st -ne 0 ] && echo "ERROR: ${@}"
	printf "${gUsageString}\n"
	exit $st
}

#If no arguments given, display help string and exit
[ $# -eq 0 ] && DisplayUsageFn 0 "Need proper arguments"

ValidateFilePathFn ()
{
	[ ! -f $1 ] && DisplayUsageFn -2 "$1: No such file"
}

ValidateDirPathFn ()
{
	[ ! -d $1 ] && DisplayUsageFn -3 "$1: No such directory"
}

vimCallFn ()
{
	f="${1}"
	v="${2}"
	shift; shift; # shift past filename and vim function name
	if [ $# -gt 0 ]; then
		arglist="'$1'"
		shift; # shift past this argument to next one
		while [[ $# -gt 0 ]]; do
			arglist=${arglist}", '$1'"
			shift; # shift past this argument to next one
		done
	fi
	#echo -e "vim $f -c\"source vimpro.vim\" -c\"call $v (${arglist})\"\n"
	vim $f -c"source vimpro.vim" -c"call $v (${arglist})"
}

while [[ $# -gt 0 ]]; do
	opt="$1"
	case $opt in
		-i)
			ValidateFilePathFn $2
			vimCallFn $2 IndentThisFile
			shift; shift # shift past current argument and value
			;;
		-I)
			ValidateDirPathFn $2
			vimCallFn $2 IndentAllFiles
			shift; shift # shift past current argument and value
			;;
		-r)
			ValidateFilePathFn $2
			read -p "Replace $3 with $4 in file $2? (y|n): " ok
			[ "$ok" == "y" ] && vimCallFn $2 ReplaceStringInThisFile $3 $4
			shift; shift # shift past current argument and value
			shift; shift # shift past old and new string args
			;;
		-R)
			ValidateDirPathFn $2
			read -p "Replace $3 with $4 in all files in directory $2? (y|n): " ok
			[ "$ok" == "y" ] && vimCallFn $2 ReplaceStringInAllFiles $3 $4
			shift; shift # shift past current argument and value
			shift; shift # shift past old and new string args
			;;
		-l)
			ValidateFilePathFn $2
			vimCallFn $2 ConvertToSyslogInThisFile $3
			shift; shift # shift past current argument and value
			shift; # shift past old print-function arg
			;;
		-L)
			ValidateDirPathFn $2
			vimCallFn $2 ConvertToSyslogInAllFiles $3
			shift; shift # shift past current argument and value
			shift; # shift past old print-function arg
			;;
		*)
			DisplayUsageFn -1 "Unknown Option: $opt"
			;;
	esac
done

exit 0
