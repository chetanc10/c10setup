#!/bin/bash

_stopped=`date`

if [ -z "$1" ]; then
	echo "stopped @ $_stopped"
else
	# It only makes sense for th user to do something like:
	# tstart.sh outfile; log-running-process; tstop.sh outfile
	# thus same file stores both start and stop times;
	# so we use >> instead of > redirection
	echo "stopped @ $_stopped" >> $1
fi
