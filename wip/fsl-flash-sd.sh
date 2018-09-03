
#!/bin/bash

maindir=$PWD
android_builddir=$PWD/android_build

flash_script_dir=$android_builddir/device/fsl/common/tools/
flash_script=fsl-sdcard-partition.sh

_usage () {
	echo "Usage: source ./imx-o8.0.0_1.0.0_ga/fsl-sdcard-flash.sh <board> <sdx>
	board options:
		sabresd_6dq
		navico
	sdx: Could be sdb, sdc (it's sdc generally), sdd, sdf, etc. Care to be taken or system disk could be corrupted.
	NOTE: source it from directory containing imx-o8.0.0_1.0.0_ga and do this in root session"
}

__is_image_created () {
	[ ! -f "$1" ] && echo "$1: File not found!" && return 4
	return 0
}

_verify_images_created_imx6 () {
	#__is_image_created fsl-sdcard-partition.sh*

	__is_image_created partition-table-14GB.img || return $?
	__is_image_created partition-table-28GB.img || return $?
	__is_image_created partition-table.img || return $?

	__is_image_created u-boot-imx6dl.imx* || return $?
	__is_image_created u-boot-imx6q-ldo.imx* || return $?
	__is_image_created u-boot-imx6q.imx* || return $?
	__is_image_created u-boot-imx6qp-ldo.imx* || return $?
	__is_image_created u-boot-imx6qp.imx* || return $?

	__is_image_created boot-imx6dl.img || return $?
	__is_image_created boot-imx6q-ldo.img || return $?
	__is_image_created boot-imx6q.img || return $?
	__is_image_created boot-imx6qp-ldo.img || return $?
	__is_image_created boot-imx6qp.img || return $?

	__is_image_created system.img || return $?
	__is_image_created vendor.img || return $?

	__is_image_created recovery-imx6dl.img || return $?
	__is_image_created recovery-imx6q-ldo.img || return $?
	__is_image_created recovery-imx6q.img || return $?
	__is_image_created recovery-imx6qp-ldo.img || return $?
	__is_image_created recovery-imx6qp.img || return $?

	return 0
}

if [ "$USER" != "root" ]; then
	echo "Not root session!"
	_usage
	return 1
fi

if [ ! -d "$android_builddir" ]; then
	echo "$android_builddir: No such directory!"
	_usage
	return 1
fi

[ ! -x "$flash_script_dir/$flash_script" ] && \
	echo "$flash_script_dir/$flash_script: Executable not found!" && return 3

# Validate board type argument
if [ -z "$1" ]; then
	echo "Need a board type argument!"
	_usage
	return 1
fi
case $1 in
	"sabresd_6dq")
		soc=imx6q
		;;
	"navico")
		echo "Board navico is TODO!"
		soc=imx6qp
		return 0
		;;
	"navico_mx8")
		echo "Board navico_mx8 is FUTURE!"
		return 0
		;;
	*)
		echo "Board $1 not supported!"
		_usage
		return 1
		;;
esac
imx_board=$1
echo "Selected board: $imx_board"

# Validate sd card /dev/ entry
if [ -z "$2" ]; then
	echo "Need a sd card argument!"
	_usage
	return 1
fi
case $2 in
	"sda" | "sdb" | "sdc" | "sdd" | "sdf")
		if [ ! -e  /dev/$2 ]; then
			_usage
			return 1
		fi
		;;
	*)
		echo "Disk $2 is invalid"
		_usage
		return 1
		;;
esac
target_sd=/dev/$2
echo "Selected target SD: $target_sd"

cd $android_builddir

img_dir=$android_builddir/out/target/product/$imx_board/
[ ! -d "$img_dir" ] && \
	echo "$img_dir: Directory not found!" && return 2

cd $img_dir
case $imx_board in
	"sabresd_6dq")
		_verify_images_created_imx6
		_ret=$?
		[ $_ret != 0 ] && \
			echo "Images not found for $imx_board" && return $_ret
		;;
	"navico")
		_verify_images_created_imx6
		_ret=$?
		[ $_ret != 0 ] && \
			echo "Images not found for $imx_board" && return $_ret
		;;
esac
echo "Found all the required images for $imx_board @ $img_dir"

cp $flash_script_dir/$flash_script $img_dir/

echo "Setting up $target_sd for $imx_board..."
./$flash_script -f $soc $target_sd
[ "$?" != "0" ] && \
	echo "Setup of $target_sd for $imx_board failed" && return 5

sync

echo "$target_sd is setup for $imx_board. $target_sd can be removed safely."
cd $maindir
return 0
