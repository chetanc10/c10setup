#!/bin/bash

gUsageString="
Usage: $0 <option>
Options:
-n <lapse>        - Raise poke after sometime
                    <lapse> = integer with PokeTimeUnits below
                              e.g. 0m => right now!
                              e.g. 5d => after 5 days
-t <time> [date]  - Poke at specific time & optionally date
                    <time> e.g. 1pm, 2:24am, 13, 15:37 [NO SPACES]
                    [date] = mm/dd[/yyyy] e.g.: 04/30/2022, 9/27/22
-r <recur> [cnt]  - Optional recurrence setup
                    <recur> = recursion interval in PokeTimeUnits
                              e.g. 0s => no gap between recurrences
                              e.g. 3h => recur pokes every 3 hours
                              e.g. 10d => no gap between pokes
                    [cnt] = Recurrence count after which poke is removed
                            Expected >= 0.
                            If -r comes with no count, count defaults to 1
-l <list-pokes>   - list all existing pokes
-d <poke-id>      - delete pending poke; specify id of poke
-m <message>      - Message string to display when poke happens
-c <poke-cmd>     - For a cmd must run instead of displaying a message
                    Known Bash command or absolute path to a script
                    TODO

PokeTimeUnits: Standard limits of each unit applies as per invocation
s - seconds, m - minutes, h - hours, d - day, w - week, M - Month, y - year

NOTE: Each successful poke created is assigned a unique ID
"

## Script actually starts executing @ SOBASS ##

########################## Helper Functions

DisplayUsageFn ()
{
	st=$1
	shift
	[ $st -ne 0 ] && echo "ERROR: ${@}" 1>&2
	printf "${gUsageString}\n"
	exit $st
}

ValidateTimeArgFn ()
{
	tmrec=${1}; shift

	[[ ${1} =~ ^[0-9smhdwMy]+$ ]] || return 1 #skip if not expected-arg
	n=${1}; shift

	# lapse/recur time syntax: 0m, 5d, etc
	# only recur has recur-cnt as next arg, not lapse
	[ ${#n} -eq 1 ] && DisplayUsageFn -9 "Invalid ${tmrec} argument: ${n}"

	## Parse and setup lapse or recursion time now
	time=$(echo ${n::-1})
	( [ -z "$time" ] || ! [[ $time =~ ^[0-9]+$ ]] ) && \
		DisplayUsageFn -10 "Invalid Recurrence argument: ${n}"
	unit=$(echo ${n: -1})
	[[ $unit =~ ^[smhdwMy]+$ ]] || \
		DisplayUsageFn -11 "Invalid ${@} ${tmrec} unit: ${n}"
	declare -A TU=(["s"]="seconds" ["m"]="minutes" ["h"]="hours" \
		["d"]="days" ["w"]="weeks" ["M"]="months" ["y"]="years")
	if [[ $tmrec == "lapse" ]]; then
		gLapseTime=$time
		gLapseUnit=${TU[$unit]}
	else
		gRecurItvl=$time
		gRecurUnit=${TU[$unit]}
		gRecurCnt=1; shifty=1 # Recur atleast once if user didn't give a count
	fi
	[ -n "${1}" ] && [[ ${1} =~ ^[0-9]+$ ]] && gRecurCnt=${1} && shifty=2
	return $shifty
}

SetupLapseFn ()
{
	[ "${gSpecTime}" ] && \
		DisplayUsageFn -3 "Spec-time & Time-From-Now disallowed same time"
	ValidateTimeArgFn lapse ${1}
	return $?
}

SetupSpecTimeFn ()
{
	[ "${gLapseUnit}" ] && \
		DisplayUsageFn -3 "Spec-time & Time-From-Now disallowed same time"
	[ -n "${1}" ] && date -d ${1} >/dev/null 2>&1 \
		&& gSpecTime=${1} && shift || \
		DisplayUsageFn -2 "Invalid time format: $1"
	gSpecDate=$(date +"%m/%d/%Y")
	[ -n "${1}" ] && [[ ${1} =~ ^[0-9/]+$ ]] && \
		date -d "${gSpecTime} ${1}" >/dev/null 2>&1 \
		&& gSpecDate=${1} && shifty=2 || shifty=1
	return $shifty
}

DeletePokeFn ()
{
	re='^[0-9]+$'; ! [[ $1 =~ $re ]] && DisplayUsageFn -5 "Bad Poke ID"
	rm -rf ~/.poke/${1}
}

SetupPokeMsgFn ()
{
	[ -z "${@}" ] && DisplayUsageFn -4 "Need message for poke"
	gPoke="DISPLAY=:0.0 zenity --info --text=\"${@}\" &"
	gPoke="${gPoke} \npaplay ${gSound}"
}

ListPokesFn ()
{
	gDir="${HOME}/.poke"
	( [ ! -d ${gDir} ] || [ $(ls ${gDir} | wc -l) -eq 0 ] ) && \
		echo "No pokes setup now" && return
	for f in ${gDir}/*; do
		echo ${f}
		poke=$(grep "Poke invocation:" ${f} | awk -F"invocation: " '{print $2}')
		echo "$gPokeID: '${poke}'"
	done
}

########################## Environment parameters
gLapseTime=""
gLapseUnit=""
gSpecTime=""
gSpecDate=""
gRecurItvl=0
gRecurUnit=""
gRecurCnt=0
gPokeCmdLine="${@}"
gPokeID=0
gPokeFile=""
gPoke=""
gSleepSec=0
gSound=/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga

########################## START OF BASH SCRIPT (SOBASS)

#If no arguments given, display help string and exit
#TODO Since GUI added later has boxes to fill, no arguments are needed
[ $# -eq 0 ] && DisplayUsageFn 0 "Need proper arguments"

# One time setup, if not done already
if [ ! -d ~/.poke ]; then
	sudo apt update && sudo apt install cron at && mkdir -p ~/.poke
fi

while [[ $# -gt 0 ]]; do
	opt="$1"; shift
	case $opt in
		-n) SetupLapseFn ${1}; shift
			;;
		-t) SetupSpecTimeFn ${1} ${2}; shift $?
			;;
		-r) ValidateTimeArgFn recur ${1} ${2}; shift $?
			;;
		-d) DeletePokeFn ${1}; exit 0	
			;;
		-m) SetupPokeMsgFn "${@}"; break
			;;
		-l) ListPokesFn; exit 0	
			;;
	esac
done

[ -z "${gPoke}" ] && DisplayUsageFn -4 "Need message for poke"
[ -z "${gLapseUnit}" ] && [ -z "${gSpecTime}" ] && \
	DisplayUsageFn -8 "Need either specific-time or time-lapse argument!"
# Create job with unique NID
gPokeID=1; gDir="${HOME}/.poke"
while [ -f "${gDir}/$gPokeID.sh" ]; do gPokeID=$((gPokeID+1)); done
gPokeFile="${gDir}/$gPokeID.sh"

if [ -n "$gLapseTime" ]; then
	# Setup Poke after some time units
	if [ "${gLapseUnit}" == "seconds" ]; then
		dtcmd="now"
		gSleepSec=${gLapseTime}
	else
		dtcmd="now+${gLapseTime}${gLapseUnit}"
	fi
	echo "dtcmd: ${dtcmd}"
else
	# Setup Poke at specific time
	dtcmd="${gSpecTime} ${gSpecDate}"
	echo "dtcmd: ${dtcmd}"
fi

if true; then
	echo gSpecTime: ${gSpecTime}
	echo gSpecDate: ${gSpecDate}
	echo gRecurCnt: ${gRecurCnt}
	echo gRecurItvl: ${gRecurItvl}
	echo gRecurUnit: ${gRecurUnit}
	echo gLapseTime: ${gLapseTime}
	echo gSleepSec: ${gSleepSec}
	echo gLapseUnit: ${gLapseUnit}
fi

echo -e "#!/bin/sh

# Use sleep command if Time-unit is seconds, 0 means no sleep, no harm
sleep ${gSleepSec}

# User's Poke invocation: ${gPokeCmdLine}
${gPoke}
RecurCnt=$gRecurCnt

# Remove job if recursion limit is reached
[ \$RecurCnt -eq 0 ] && rm -rf ${gPokeFile} && exit 0
" > ${gPokeFile}

if [ $gRecurCnt -ne -1 ]; then
	echo "# Decrement recurrence-count" >> ${gPokeFile}
	echo "sed -i \"s/^RecurCnt=.*/RecurCnt=\$((RecurCnt-1))/\" ${gPokeFile}" \
		>> ${gPokeFile}
fi

# Setup recurring poke now
if [ "${gRecurUnit}" == "seconds" ]; then
	echo "# Setup next recurrence with sleep in seconds" >> ${gPokeFile}
	echo "dtc=\"now\"" >> ${gPokeFile}
	echo "sed -i \"s/^sleep .*/sleep ${gRecurItvl}/\" ${gPokeFile}" \
		>> ${gPokeFile}
else
	echo "# Recurrence could be in minutes, hours, ... years" >> ${gPokeFile}
	echo "dtc=\"now+${gRecurItvl}${gRecurUnit}\"" >> ${gPokeFile}
fi

echo "at \${dtc} -f ${gPokeFile}" >> ${gPokeFile}

echo ----------------------------------------
cat ${gPokeFile}
echo ----------------------------------------

at ${dtcmd} -f ${gPokeFile} #2>/dev/null
atq

exit 0
