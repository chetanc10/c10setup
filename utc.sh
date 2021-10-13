#!/bin/bash

DisplayUsage () {
	echo -e "Usage: utc.sh [YYYY-mm-dd] <HH>[:mm[:ss]]\nThis script takes a date/time in a format and returns the corresponding UTC time"
	exit $1
}

[ -z "$1" ] && DisplayUsage 0

arg="${@}"
date -d "${arg}" >/dev/null || DisplayUsage -1
dt="$(date +%Z) ${arg}"

date -d "${dt}"
date -u -d "${dt}"

echo ""

exit 0
