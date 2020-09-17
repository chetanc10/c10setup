#!/bin/bash

# Create a 

[ ! -e '/home/'$USER'/ChetaN/c10setup/cmnts.conf.sh' ] && echo "Damn!" && exit -1

source '/home/'$USER'/ChetaN/c10setup/cmnts.conf.sh'

[[ "$0" == *"cmnts.sh"* ]] && echo "Error: Can't use the script directly!" && exit -1;

# extract cmd.sh from /path/to/cmd/cmd.sh
_cmd=$(echo $0 | awk -F/ '{print $NF}')

# extract actual mount-path name from name.sh
_mntname=$(echo $_cmd | awk -F. '{print $(NF-1)}')
[ -z "$_mntname" ] && echo "Invalid mount request: $0" && exit -2

# get the /dev/sdxx for mounting
sdxx=${_cmnts[$_mntname]}
# form the mount-path from mount-name _mntname
mntpath=${_cmnts_paths[$_mntname]}
echo $mntpath: $sdxx

[ -z "$1" ] && echo "Need arg1 as y or n" && exit -3
mountit=$1

exit 0

Mntd=$(echo $(echo $(echo $0 | awk -F/ '{print $NF}')) | cut -d . -f 1)
Req=$(echo $Mntd | rev | cut -c1 | rev)
Mntd=$(echo $Mntd | cut -d . -f 1 | rev | cut -c 2- | rev)
Dev="${reqparts[$Mntd]}"

MntPath="/media/vchn075/$Mntd"

#echo "MntPath : $MntPath"
#echo "Dev     : $Dev"
#echo "Req     : $Req"

[ -z $Dev ] && echo "No Partition Device listed for $Mntd!" && exit -1
[ ! -e $Dev ] && echo "Device Partition '$Dev' doesn't exist!" && exit -2

cat /proc/mounts | grep $MntPath > /dev/null
[ $? -eq 1 ] && MntSt="n" || MntSt="y"
#echo "MntSt   : $MntSt"

#exit 0

if [ "$MntSt" == "n" ] && [ "$Req" == "y" ]; then
# 	echo Mounting!
	sudo mkdir -p $MntPath
	sudo mount $Dev $MntPath
	mret=$?
	if [ $mret -ne 0 ]; then
		echo Unable to mount Partition $Mntd!
		sudo rm -rf $MntPath
	fi
	exit $mret
elif [ "$MntSt" == "y" ] && [ "$Req" == "n" ]; then
# 	echo Unmouting!
	sudo umount $MntPath
	mret=$?
	if [ $mret == 0 ]; then
		sudo rm -rf $MntPath
	else
		echo Unable to unmount Partition $Mntd!
	fi
	exit $mret
fi

exit 0

