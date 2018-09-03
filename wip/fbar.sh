
#!bin/bash

while true
do
	[ -e "/tmp/$1" ] && break;
	sleep 10
done

return 0
