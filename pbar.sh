#!/bin/bash

gUsageString="
Usage: $0 [-h] [proc-name]
Options:
[-h]         - display this help message and exits
[proc-name]  - Optional, name of process to wait for completion
               If [proc-name] is not given, the tool assumes that it should
					alert user immediately. This is useful in cases like:
					~$ <long-process> ; $0
					NOTE: Don't use long-process <&&> $0 since
					long-process might return non-zero and $0 wouldn't run
"

DisplayUsageFn () {
	st=$1; shift;
	[ $st -ne 0 ] && echo "ERROR: ${@}"
	printf "\n${gUsageString}\n"
	exit $st
}

AlertFn () {
	[[ "$1" == "__LaPsE="* ]] && lapse=${1#"__LaPsE="} || lapse=0
	AudioFile1="/usr/share/sounds/ubuntu/stereo/phone-incoming-call.ogg"
	AudioFile2="/usr/share/sounds/freedesktop/stereo/phone-incoming-call.oga"
	[ $lapse -gt 0 ] && lapseStr=" $lapse seconds elapsed" || lapseStr=""
	[[ "${proc}" == "Prev" ]] && \
		proc="Previous Process" || proc="Process '${proc}'"
	zenity --info --text "${proc} complete.${lapseStr}" 2>/dev/null &
	[ -f ${AudioFile1} ] && AudioFile=${AudioFile1} || \
		[ -f ${AudioFile2} ] && AudioFile=${AudioFile2}
	paplay $AudioFile
}

ProcFind () {
	pn=$(ps aux | grep ${1} | grep -v "grep\|${pbar}")
	pst=$?
	echo $pst
}

[ "$1" == "-h" ] && DisplayUsageFn 0

if [ $# -eq 0 ]; then
	echo "No process name given"
	proc="Prev"
	# If no process name is given, pbar is invoked as :
	# long-process ; pbar.sh
	# We can't know that process name, so just call it 'Prev'
	AlertFn "Prev"
	exit 0
fi

pbar=$0
proc=${@}

FALSE=0
TRUE=1

terminated=$(ProcFind ${proc})
if [ $terminated -eq $TRUE ]; then
	echo "${proc}: Process not found!" && exit -1
fi

began_at=`date +%s`
echo "Going to wait now.."
while [ 1 ]; do
	terminated=$(ProcFind ${proc})
	[ $terminated -eq $TRUE ] && break
	sleep 1
done
lapse=$(($(date +%s) - $began_at))
AlertFn "__LaPsE=$lapse" ${proc}
exit 0

