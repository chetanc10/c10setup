#!/bin/bash

# Identifies and lists serial-console type tty ports in /dev/

[ -z "${1}" ] && \
	echo -e "Usage: $0 <tty-name>\ne.g. ttyS, ttymxc, ttyUSB\n" && exit 0

ttyx=${1}

for tty in $(ls /dev/${ttyx}*); do 
	ttyPropStr=$(sudo stty -F ${tty} 2>&1)
	[[ "${ttyPropStr}" == *"Input/output error"* ]] && continue
	echo -e "\n${tty} -------------------------\n${ttyPropStr}"
done

echo ""

exit 0

