#!/bin/bash

# Identifies and lists serial-console type tty ports in /dev/

ttyx=ttyS

for tty in $(ls /dev/${ttyx}*); do 
	ttyPropStr=$(sudo stty -F ${tty} 2>&1)
	[[ "${ttyPropStr}" == *"Input/output error"* ]] && continue
	echo -e "\n${tty} -------------------------\n${ttyPropStr}"
done

echo ""

exit 0

