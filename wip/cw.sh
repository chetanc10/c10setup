#!/bin/bash

aosp_build=/home/chetan.ks/ChetaN/projects/cmap_mfdx/src/pp/gerrit/CMAP_GER_18_031_AOSP_SRC/android_build
aosp_kernel=/home/chetan.ks/ChetaN/projects/cmap_mfdx/src/pp/gerrit/CMAP_GER_18_031_AOSP_SRC/android_build/vendor/nxp-opensource/kernel_imx
tagged_kernel=/home/chetan.ks/ChetaN/projects/cmap_mfdx/src/pp/gerrit/CMAP_GER_18_031_kernel_src
nrefs=/home/chetan.ks/ChetaN/projects/cmap_mfdx/src/refs/navico/home/build/references

_title_cmd="TITLE=\"\[\e]2;heli\a\]\"; PS1=$PS1${TITLE}"

#echo "Starting minicom"
#while [ 1 ]; do
	#[ ! -e /dev/ttyUSB0 ] && echo "/dev/ttyUSB0 not found. Connect console cable and press Enter" || break
	#read _answer
#done
#gnome-terminal -e "bash -c \"cd ~; sudo minicom; echo \"Press ENTER\"; read answer\""

#gnome-terminal --tab -e "bash -c \"cd $aosp_build; c10t aosp_build; sudo su; exec bash\""

gnome-terminal \
	--tab --working-directory=$aosp_build -e "bash -c \"exec $_title_cmd; exec bash\"" #-x /home/chetan.ks/ChetaN/projects/cmap_mfdx/misc/title.sh aosp_build
	#--tab -e "bash -c \"cd /home/chetan.ks/ChetaN/projects/cmap_mfdx/src/pp/gerrit/CMAP_GER_18_031_AOSP_SRC/android_build/vendor/nxp-opensource/kernel_imx; exec bash\"" \
	#--tab -e "bash -c \"cd /home/chetan.ks/ChetaN/projects/cmap_mfdx/src/refs/navico/home/build/references; exec bash\""
#gnome-terminal -e "bash -c \"cd /home/chetan.ks/ChetaN/projects/cmap_mfdx/src/pp/gerrit/CMAP_GER_18_031_AOSP_SRC/android_build/vendor/nxp-opensource/kernel_imx; exec bash\""

