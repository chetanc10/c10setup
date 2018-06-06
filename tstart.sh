#!/bin/bash

_started=`date`

if [ -z "$1" ]; then
	echo "started @ $_started"
else
	echo "started @ $_started" > $1
fi
