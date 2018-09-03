#!/bin/bash

IN_TIME_MAX='1100'

if [ ! -e ~/.c10_intime ]; then
	# If this is not our first login after IN_TIME_MAX, then we say it's LOGIN_TIME
	_now=`date +'%H%M'`
	echo $_now
	if [ $_now -g $IN_TIME_MAX ]; then
	fi
else
	# If this is an intermediate reboot during working hours, do nothing (?)
fi
