#!/bin/bash

gUsageString="
Usage: $0 <option>
Options:
-n <time-lapse> [recur]   - Number of time-units to elapse for nudge
                            Units: s-seconds, m-minutes, h-hours, d-days
                            e.g. 5s, 13m, 7h, 2d
                            recur - optional, recurrence-count after 1st nudge
									 -1  => infinite recurrences
                            0   => no recurrences
                            > 0 => definite recurrences count
-t <spec-time> [date] [recur-[cnt]] - Nudge at specific time & optionally date
                            e.g. 1pm 29/3/20, 2:24pm, 13, 14:24 1/5
                            [recur-[cnt]] - Opional, Indiates recurrence
                            Recurrence args - s, m, h, d, w, M, y
									 Count - refer [recur] of option '-n'
                            e.g. m--1 => recur every minute infinitly
                            e.g. w-5 => recur for 5 weeks
                            e.g. d-0 => Don't care, no recurrence due to 0
-d <nudge-id>             - delete pending nudge; specify id of nudge
-m <message>              - Message string to display when nudge happens
-r <run-cmd>              - For a cmd must run instead of displaying a message
                            Known Bash command or absolute path to a script
                            TODO

NOTE: Each successful nudge created is assigned a unique ID
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
#TODO Since GUI added later has boxes to fill, no arguments are needed
[ $# -eq 0 ] && DisplayUsageFn 0 "Need proper arguments"

# One time setup, if not done already
if [ ! -d ~/.nudge ]; then
	sudo apt update && sudo apt install cron at && mkdir -p ~/.nudge
fi

gTfnCount=0
gTfnUnit=""
gSpecTime=""
gRecurs=0
gNID=0
gNF=""
gNC=""
declare -A tfnu=(["s"]="second" ["m"]="minute" ["h"]="hour" ["d"]="day")

nsound=/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga

while [[ $# -gt 0 ]]; do
	opt="$1"; shift
	case $opt in
		-n)
			[ "${gSpecTime}" ] && \
				DisplayUsageFn -3 "Spec-time & Time-From-Now disallowed same time"
			tfn=${1}; gTfnCount=${tfn//[!0-9]/}; gTfnUnit=${tfn: -1}
			[[ "smhd" != *"$gTfnUnit"* ]] && DisplayUsageFn -1 "Invalid time-unit"
			shift
			re='^-?[0-9]+$'; [[ $1 =~ $re ]] && gRecurs=$1 && shift
			echo "recurs: $gRecurs"
			;;
		-t)
			[ "${gTfnUnit}" ] && \
				DisplayUsageFn -3 "Spec-time & Time-From-Now disallowed same time"
			DisplayUsageFn -2 "Not supported yet"
			shift
			;;
		-d)
			re='^[0-9]+$'; ! [[ $1 =~ $re ]] && DisplayUsageFn -5 "Bad Nudge ID"
			rm -rf ~/.nudge/${1} && exit
			;;
		-m)
			[ -z "${@}" ] && DisplayUsageFn -4 "Need message for nudge"
			gNC="DISPLAY=:0.0 zenity --info --text=\"${@}\" & \npaplay ${nsound}"
			break
			;;
	esac
done

[ -z "${gNC}" ] && DisplayUsageFn -4 "Need message for nudge"

if [ -z "$gTfnUnit" ]; then
	# Setup Nudge at specific time
	#TODO
	exit 0
fi

# Setup Nudge after some time units
gTfnUnit=${tfnu[$gTfnUnit]}
if [ "${gTfnUnit}" == "second" ]; then
	tfn="now"
	NudgeSleepSeconds="sleep ${gTfnCount}"
else
	tfn="now+${gTfnCount}${gTfnUnit}"
fi

# Create job with unique NID
gNID=1
while [ -f "${HOME}/.nudge/j$gNID.sh" ]; do gNID=$((gNID+1)); done
gNF="${HOME}/.nudge/$gNID.sh"

echo -e "#!/bin/sh
${NudgeSleepSeconds}
${gNC}
nRecur=$gRecurs
# Remove job if recursion limit is reached
[ \$nRecur -eq 0 ] && rm -rf ${gNF} && exit 0
# Skip recursion-count decrement & exit, if job is to run infinitely
[ $gRecurs -eq -1 ] && exit 0
# Decrement definitive recursion-count
n=\$((nRecur-1))
sed -i \"s/^nRecur=.*/nRecur=\$n/\" ${gNF}
at ${tfn} -f ${gNF}
" > "${gNF}"
at ${tfn} -f ${gNF} 2>/dev/null

exit 0
