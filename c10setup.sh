#!/bin/bash

_print_usage () {
	echo -e "\nI'm an Interactive Installer Program for basic system utilities and libraries. Enter 'x' during any stage of questioning from me to kill me. I'll notify in visual and audible manner about completion of selected setup.
Entering 'n' or just pressing <ENTER> will be considered as choice for 'NO'.

Usage: ./c10setup.sh <alert_type> [setup_type <setup_choice>]

alert_type:
	-z to use 'zenity' (GUI visual notification)
	-e to use 'echo' (Console visual notification)

setup_type: Optional. Defaults to full c10setup asking for all libs/utils/scripts/rems.
	-f for full c10setup asking for all full-apt-get-update/must-have-packages/libs/utils/scripts/etc
	-s for selecting specific group - libs/utils/scripts/rems.
		setup_choice is must and is one of following: 
			lib 	select libraries group
			util 	select utilities group
			script  select scripts group
			rem     select removables group (removes targets)"

	exit 0
}

invoked=$0

dir_c10setup=`dirname $invoked`
[ "$dir_c10setup" == "." ] && dir_c10setup=$PWD

sound_success=/usr/share/sounds/freedesktop/stereo/complete.oga
sound_failure=/usr/share/sounds/freedesktop/stereo/suspend-error.oga

alert_type="z"

__alert_func () {
	if [ "$alert_type" == "z" ]; then
		zenity --info --text="$1" 2>/dev/null
	else # no zenity, just echo on terminal
		echo -e "$1"
	fi
}

# Invocation: _notify_when_done <$? or other status value> <package-name> <description or extra messages>
_notify_when_done () {
	if [ "$1" == "0" ]; then # Success case
		[ -e $sound_success ] && paplay $sound_success &
		__alert_func "$2: SUCCESS"
	else # Failure case
		[ -e $sound_failure ] && paplay $sound_failure &
		if [ -z "$3" ]; then
			__alert_func "$2: FAILURE"
		else
			__alert_func "$2: FAILURE\nReason: $3"
		fi
	fi
}

_install_skype () {
	local user_deb=0
	echo "If you have a 'skypeforlinux-64.deb' already, please enter the absolute file-path with name so that I can install from there. If you don't have it, enter 'n'"
	read fpath
	if [ ! -f "$fpath" ]; then
		[ "$fpath" != "n" ] && echo "!!!!!!!!!!!!!!!Invalid filepath: $fpath.. I'm taking over now"
		echo "Downloading latest skypeforlinux debian file into /tmp/"
		wget https://repo.skype.com/latest/skypeforlinux-64.deb -O /tmp/skypeforlinux-64.deb
		[ "$?" != "0" ] && rm -rf /tmp/skypeforlinux-64.deb && _notify_when_done 1 "Install skype" "wget https://repo.skype.com/latest/skypeforlinux-64.deb failed" && return
		skype_deb_path=/tmp/skypeforlinux-64.deb
	else
		skype_deb_path=$fpath
		user_deb=1
	fi
	sudo dpkg -i $fpath
	if [ "$?" != "0" ]; then
		[ "$user_deb" == "0" ] && rm -rf $fpath
		_notify_when_done 1 "Install skype" "dpkg -i $fpath failed"
		return
	fi
	sudo apt install -f
	_notify_when_done $? "Install skype" "Installed skypeforlinux. Move (or Remove) $fpath as you need and then click on OK here.."
}

_install_youtube_dl () {
	echo -ne "Default apt-get based installation seems to be buggy.. I'm approaching the website and get it for you "
	sudo curl -L https://yt-dl.org/latest/youtube-dl -o /usr/local/bin/youtube-dl
	[ "$?" != "0" ] && _notify_when_done 1 "Install youtube-dl" "curl -L https://yt-dl.org/latest/youtube-dl -o /usr/local/bin/youtube-dl" && return
	sudo chmod a+rx /usr/local/bin/youtube-dl
	echo "Installed youtube-dl. You might consider using the following to resolve avconv errors during downloads using youtube-dl:"
	echo "youtube-dl -f 137+140 --prefer-ffmpeg <youtube-link>"
	_notify_when_done $? "Install youtube-dl"
}

_install_qemu () {
	this_machine=`uname -m`
	[ "$this_machine" != "x86_64" ] && _notify_when_done 1 "Install qemu" "Currently I support only x86_64 systems" && return
	echo "Need to install qemu for x86_64 architecture.. But there's a whole bunch of dependencies/subdependencies to be installed first."
	echo "Following do the job: qemu-kvm qemu-system-x86 virt-manager virt-viewer libvirt-bin"
	sudo apt-get install qemu-kvm qemu-system-x86 virt-manager virt-viewer libvirt-bin
	_notify_when_done $? "Install qemu"
	return
}

_install_tftp_server () {
	echo "Installing tftp-server dependencies: xinetd tftpd tftp"
	sudo apt-get install xinetd tftpd tftp
	[ "$?" != "0" ] && _notify_when_done 1 "Install tftp_server" "failed to apt-get install"
	echo "Setting up a hookup script to link a /tftpboot folder to tftp-server"
	sudo touch /etc/xinetd.d/tftp && sudo chown $USER /etc/xinetd.d/tftp && sudo chmod +w /etc/xinetd.d/tftp
	[ "$?" != "0" ] && _notify_when_done 1 "Install tftp_server"
	sudo echo "service tftp
	{
		protocol        = udp
		port            = 69
		socket_type     = dgram
		wait            = yes
		user            = nobody
		server          = /usr/sbin/in.tftpd
		server_args     = /tftpboot
		disable         = no
	}" > /etc/xinetd.d/tftp
	echo "Setting up a user accessible /tftpboot folder to hold files for transfer by tftp-server"
	sudo mkdir -p /tftpboot && sudo chmod -R 666 /tftpboot && sudo chown -R nobody /tftpboot
	sudo /etc/init.d/xinetd restart
	_notify_when_done $? "Install tftp_server"
}

__do_save_prev_vim () {
	target=$1
	if [ -d /home/$USER/$target ]; then
		echo "JFYI, I'm can do any of the following:"
		echo "m: Move existing $target to .my$target in home directory so that you can't lose your existing plugins/addons"
		echo "d: Remove existing $target with the risk of losing existing plugins you might have setup previously"
		echo -ne "Your choice (m/d): "
		read answer
		if [ "$answer" ==  "m" ]; then
			mv /home/$USER/$target /home/$USER/.my$target
		elif [ "$answer" ==  "d" ]; then
			rm -rf /home/$USER/$target
		fi
	fi
}

_install_vim () {
	sudo chown $USER /home/$USER/.viminfo && sudo chmod a+rw /home/$USER/.viminfo
	echo -n "for VIM, c10 provides .vim and .vimrc in c10setup. The .vim and .vimrc have some plugins and keymaps which become very handy for a Vimmer. If you want them, I can place them in your HOME as .vim and .vimrc replacing existing ones. Shall I install .vim/.vimrc?(y|n): "
	read answer
	if [ "$answer" == "y" ]; then
		echo "Installing c10 collections for vim plugins and keymaps.. Good for you!"
		__do_save_prev_vim ".vim"
		mkdir /home/$USER/.vim
		cp -r $dir_c10setup/.vim/* /home/$USER/.vim/
		__do_save_prev_vim ".vimrc"
		cp $dir_c10setup/.vimrc /home/$USER/.vimrc
	fi
	exit_if_requested $answer
}

_install_arc_dark () {
	echo "I just need to add noobslab to ppa repo listing, update package list, install package 'arc-theme'.. Then you can use unity-tweak-tool to choose any theme"
	sudo add-apt-repository ppa:noobslab/themes
	_notify_when_done $? "Install dark-theme"
	sudo apt-get update
	sudo apt-get install arc-theme
	_notify_when_done $? "Install dark-theme"
}

declare -a c10utils=(vim cscope exuberant-ctags curl git at tree ifstat dconf-editor unity-tweak-tool valgrind minicom tftp-server lftp subversion meld ssh rar unrar openvpn vlc tomboy nmap artha skype youtube-dl gparted synaptic wifi-radar wireshark qemu unity-dark-theme net-tools)
cnt_c10utils=${#c10utils[@]}

list_c10utils () {
	for i in "${!c10utils[@]}"; do 
		local iter=$((i+1))
		printf '%2d) %-24s' "$i" "${c10utils[i]}"
		[ $iter -ne 0 ] && [ $(($iter%3)) -eq 0 ] && echo ""
	done
}

# This handles normal installables and also special utilities/apps which are not simple/proper apt-get installables
_install_c10util () {
	local do_aptget_install=0
	case "$1" in
		"skype")
			_install_skype
			;;
		"youtube-dl")
			_install_youtube_dl
			;;
		"qemu")
			_install_qemu
			;;
		"tftp-server")
			_install_tftp_server
			;;
		"vim")
			_install_vim
			do_aptget_install=1
			;;
		"unity-dark-theme")
			_install_arc_dark
			;;
		*)
			do_aptget_install=1
			;;
	esac
	if [ $do_aptget_install -eq 1 ]; then
		echo -e "Installing $1"
		sudo apt-get install $1
		_notify_when_done $? "Install $1"
	fi
}

install_c10utils () {
	local _desc
	for i in "${c10utils[@]}"; do
		case "$i" in
			"skype")
				_desc="Telecommunications application that specializes in providing voice/video/messaging chat"
				;;
			"unity-dark-theme")
				_desc="Dark theme from unity - Power efficient and light-sensitive-eye-friendly theme"
				;;
			"tftp-server")
				_desc="A tftp server working with xinetd"
				;;
			*)
				_desc=$(apt-cache search ${i} | grep '^${i} ')
				echo ">>>>>>>> $_desc"
				;;
		esac
		echo -ne "\n\n****${_desc}\nInstall '$i'?(y|n): "
		read answer
		[ "$answer" == "y" ] && _install_c10util "$i"
		# We don't test for exit choice before "y" as that's mostly unlikely choice
		exit_if_requested $answer
	done
}

declare -a c10libs=(libpcap-dev libncurses5-dev libelf-dev libssl-dev ffmpeg libav-tools x264 x265)
cnt_c10libs=${#c10libs[@]}

list_c10libs () {
	for i in "${!c10libs[@]}"; do 
		local iter=$((i+1))
		printf '%2d) %-24s' "$i" "${c10libs[i]}"
		[ $iter -ne 0 ] && [ $(($iter%3)) -eq 0 ] && echo ""
	done
}

_install_c10lib () {
	echo -e "Installing $1"
	sudo apt-get install $1
	_notify_when_done $? "Install $1"
}

install_c10libs () {
	for i in "${c10libs[@]}"; do
		echo -ne "\n\n****Install '$i'?(y|n): "
		read answer
		[ "$answer" == "y" ] && _install_c10lib "$i"
		exit_if_requested $answer
	done
}

declare -a c10scripts=()
cnt_c10scripts=0
_build_c10scripts () {
	local filename
	for file in "$dir_c10setup"/*.*; do
		filename=$(basename $file)
		[ "$filename" == "README.md" ] && continue;
		[ "$filename" == "c10setup.sh" ] && continue;
		[ "$filename" == "wip" ] && continue; # Work In Progress!
		c10scripts+=("$filename")
	done
	cnt_c10scripts=${#c10scripts[@]}
}

list_c10scripts () {
	_build_c10scripts
	for i in "${!c10scripts[@]}"; do 
		local iter=$((i+1))
		printf '%2d) %-24s' "$i" "${c10scripts[i]}"
		[ $iter -ne 0 ] && [ $(($iter%3)) -eq 0 ] && echo ""
	done
}

_install_c10script () {
	sudo rm -f /usr/bin/$1
	sudo ln -s "$file" /usr/bin/$1
	_notify_when_done $? "Install $1"
}

install_c10scripts () {
	echo "I'll just setup a soft link for all the requested scripts. So you MUST keep this folder in this directory or move it somewhere else and invoke from that directory"
	echo "Everytime you move this directory, you'll need to run c10setup.sh from the new path so that the soft-links are not broken.. I warned ya!"
	local filename
	for file in "$dir_c10setup"/*.*; do
		filename=$(basename $file)
		[ "$filename" == "README.md" ] && continue;
		[ "$filename" == "c10setup.sh" ] && echo "I'll not setup soft-link for c10setup.sh as it may break if this folder moves and you shouldn't be relying only on c10setup softlink" && continue;
		echo -ne "\n\n****Install '$filename'?(y|n): "
		read answer
		[ "$answer" == "y" ] && _install_c10script "$filename"
		exit_if_requested $answer
	done
}

declare -a c10rems=(rhythmbox brasero shotwell empathy totem thunderbird* deja-dup*)
cnt_c10rems=${#c10rems[@]}

list_c10rems () {
	for i in "${!c10rems[@]}"; do 
		local iter=$((i+1))
		printf '%2d) %-24s' "$i" "${c10rems[i]}"
		[ $iter -ne 0 ] && [ $(($iter%3)) -eq 0 ] && echo ""
	done
}

_uninstall_c10rem () {
	sudo apt-get remove --purge $1
	_notify_when_done $? "Uninstall $1"
}

uninstall_c10rems () {
	for i in "${c10rems[@]}"; do
		echo -ne "\n\n****Remove '$i'?(y|n): "
		read answer
		[ "$answer" == "y" ] && _uninstall_c10rem "$i"
		exit_if_requested $answer
	done
}

setup_c10bash () {
	local replacer="${dir_c10setup}/.c10bashsetup.sh"

	# For paths/special variables/symbols in filenames to work properly in sed -s, make them specially parse-able using '\any-special-symbol'
	replacer=$(printf '%s' "${replacer}" | sed 's/[[\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')

	sed -i -e "s/\~\/\.bash_aliases/${replacer}/g" /home/$USER/.bashrc

	echo "Setup done for c10bash"
}

exit_if_requested () {
	[[ "$1" == "x" ]] && echo -e "\nExiting c10setup...\n" && exit 0
}

## Validate arguments ##

argCount="$#"
[ $argCount -lt 1 ] && echo -e "\nError: Invalid argument count" && _print_usage

# Validate alert_type
case "$1" in
	"-z" | "-e")
		alert_type=$1
		;;
	*)
		echo -e "\nError: Invalid argument for alert_type: $1"
		_print_usage
		;;
esac

## Check if setup_type is selective or full setup and act accordingly ##

#Usage: _validate_idx <idx_value> <first_idx_allowed> <last_idx_allowed>
_validate_idx () {
	[[ ( $1 -lt $2 ) || ( $1 -gt $3) ]] && echo "Invalid index: $1" && exit -1
}

# Validate and act on selective setup
if [ ! -z "$2" ] && [ "$2" == "-s" ] ; then
	[ $argCount -ne 3 ] && echo -e "\nError: No setup_choice provided for selective setup!" && _print_usage
	case "$3" in
		"lib")
			list_c10libs
			last_idx=$(($cnt_c10libs-1))
			echo -ne "\n\nSelect a library by it's index (0-$last_idx): "
			read idx
			_validate_idx $idx 0 $last_idx
			_install_c10lib ${c10libs[$idx]}
			;;
		"util")
			list_c10utils
			last_idx=$(($cnt_c10utils-1))
			echo -ne "\n\nSelect a utility by it's index (0-$last_idx): "
			read idx
			_validate_idx $idx 0 $last_idx
			_install_c10util ${c10utils[$idx]}
			;;
		"rem")
			list_c10rems
			last_idx=$(($cnt_c10rems-1))
			echo -ne "\n\nSelect a remity by it's index (0-$last_idx): "
			read idx
			_validate_idx $idx 0 $last_idx
			_uninstall_c10rem ${c10rems[$idx]}
			;;
		"script")
			list_c10scripts
			last_idx=$(($cnt_c10scripts-1))
			echo -ne "\n\nSelect a script by it's index (0-$last_idx): "
			read idx
			_validate_idx $idx 0 $last_idx
			_install_c10script ${c10scripts[$idx]}
			;;
		*)
			echo -e "\nError: Invalid setup_choice: $3" && _print_usage
			;;
	esac
	echo -e "\nTata!\n"
	exit 0
fi

# Just confirm if it is full setup
[ ! -z "$2" ] && [ "$2" != "-f" ] && echo -e "\nError: Invalid setup_type: $2" && _print_usage

#_notify_when_done 0 "sample test" "damned"; exit 0

echo -ne "\nTrying to install normal updates/dependencies. Shall I proceed?(y|n): "
read answer
if [ "$answer" == "y" ]; then
	sudo apt-get update
	sudo apt-get install -f
fi
exit_if_requested $answer

echo -ne "\nTrying to install basic important libs, dependencies, manpages, etc. Shall I proceed?(y|n): "
read answer
# Revisit if we find that the following's going to become a list of libs/stuffs/etc
if [ "$answer" == "y" ]; then
	sudo apt-get install manpages-posix-dev exfat-fuse exfat-utils byobu
	# TODO - for using ./configure generated by autoconf - autoconf automake gperf bison flex texinfo help2man gawk libtool libtool-bin
	_notify_when_done 1 "Install manpages-posix-dev"
fi
exit_if_requested $answer

echo -ne "\nDo you need utility Installations? (y|n): "
read answer
[[ "$answer" == "y" ]] && install_c10utils
exit_if_requested $answer

echo -ne "\nProceed to lib Installations? (y|n): "
read answer
[[ "$answer" == "y" ]] && install_c10libs
exit_if_requested $answer

echo -ne "\nProceed to add c10 scripts to filesystem? (y|n): "
read answer
[[ "$answer" == "y" ]] && install_c10scripts
exit_if_requested $answer

echo -e "\n***************************BEWARE***************************\nDURING UNINSTALLATIONS, PLEASE BE VERY CAREFUL AND OBSERVE WHICH PACKAGES ARE ADDITIONALLY REMOVED ALONG WITH REQUESTED UNINSTALLATION AND DECIDE IF YOU WANT TO PROCEED! OTHERWISE, KEEP AWAY!"
echo -ne "Proceed to UNInstallations? (y|n): "
read answer
[[ "$answer" == "y" ]] && uninstall_c10rems
exit_if_requested $answer

echo -ne "\nSetup c10bash? (y/n): "
read answer
[[ "$answer" == "y" ]] && setup_c10bash
exit_if_requested $answer

echo -e "\nTata!\n"
