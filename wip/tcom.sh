#!/bin/bash

idx=0
ttyx=ttyS
while true; do
	dev=/dev/${ttyx}${idx}
	[ ! -e ${dev} ] && break
	sudo stty -F ${dev} 2>/dev/null > /tmp/tmpfile
	#sudo stty -F ${dev} > /tmp/tmpfile
	#grep "icanon" /tmp/tmpfile
	grep -q "brkint" /tmp/tmpfile
	if [ $? -eq 0 ]; then
		echo -ne "\n\n-- ${dev} ------------------\n"
		cat /tmp/tmpfile
	fi
	idx=$((idx+1))
done

exit 0

for tty in $(ls /dev/ttyS*); do 
	portErrStatus=$(stty -F $tty -a 2>&1)
	if [[ "$portErrStatus" == *"Input/output error"* ]]; then
		touch /tmp/111111
	else
		ttyProperty=$(stty -F $tty)
		speed=$(echo $ttyProperty | grep speed | awk '{print $2}')
		if [ $speed -ge 0 ]; then
			echo -ne "\n--- $tty: \n$ttyProperty\n"
		fi
	fi
done
