#!/bin/bash

_print_usage ()
{
	printf "
This is a program to setup essential/basic system utilities, libraries, custom-scripts etc with audio/visual notification support on each setup completion.

Usage: c10setup.sh <Options>
Options:
    -i - the script runs in interactive mode for each tool setup
	-n - for non-interactive tool setup. optional tools are still setup 
         interactively, to avoid unwanted optional tool installations.

- Interactive Tool Setup Choices:
<y|n|x> - For each tool-setup, the script will ask to choose to act, some of them generic as described below.
    y - user says YES install/setup that tool
    n - user says NO to install/setup that tool
        (if user <ENTER>s without inputing choice script takes it as NO)
    x - user says EXIT the program immediately

- Soft-links:
The script will create soft-links to custom-scripts. So please ensure this directory as is stays forever in same path as during installation.

"
	[ $1 -ne 0 ] && exit $?
}

dir_c10setup=`dirname $0`
[ "$dir_c10setup" == "." ] && dir_c10setup=$PWD

__alert_func ()
{
	if [ `which zenity` ] && [ -z "$SSH_TTY" ]; then
		zenity --info --text="$1" 2>/dev/null
	else # no zenity, just echo on terminal
		echo -e "$1"
	fi
}

# Invocation: _notify_when_done <$? or other status value> <package-name> <description or extra messages>
_notify_when_done ()
{
	SoundPass=/usr/share/sounds/freedesktop/stereo/complete.oga
	SoundFail=/usr/share/sounds/freedesktop/stereo/suspend-error.oga
	if [ "$1" == "0" ]; then # Success case
		[ -e $SoundPass ] && paplay $SoundPass &
		__alert_func "$2: SUCCESS"
	else # Failure case
		[ -e $SoundFail ] && paplay $SoundFail &
		failStr="$2: FAILURE"
		[ "$3" ] && failStr=${failStr}"\nReason: $3"
		__alert_func ${failStr}
	fi
}

_install_skype ()
{
	echo "Downloading latest skypeforlinux debian file into /tmp/"
	wget https://repo.skype.com/latest/skypeforlinux-64.deb -O /tmp/skypeforlinux-64.deb
	[ "$?" != "0" ] && rm -rf /tmp/skypeforlinux-64.deb && _notify_when_done 1 "Install skype" "wget https://repo.skype.com/latest/skypeforlinux-64.deb failed" && return
	fpath=/tmp/skypeforlinux-64.deb
	sudo dpkg -i $fpath
	_notify_when_done $? "Install skype" "dpkg -i $fpath failed" && return
	sudo apt install -f
	_notify_when_done $? "Install skype" "apt install -f failed"
	rm -rf $fpath
}

_install_youtube_dl ()
{
	echo -ne "Default apt-get based installation seems to be buggy.. Downloading from website"
	sudo curl -L https://yt-dl.org/latest/youtube-dl -o /usr/local/bin/youtube-dl
	[ "$?" != "0" ] && _notify_when_done 1 "Install youtube-dl" "curl -L https://yt-dl.org/latest/youtube-dl -o /usr/local/bin/youtube-dl" && return
	sudo chmod a+rx /usr/local/bin/youtube-dl
	echo "Installed youtube-dl. You might consider using the following to resolve avconv errors during downloads using youtube-dl:"
	echo "youtube-dl -f 137+140 --prefer-ffmpeg <youtube-link>"
	_notify_when_done $? "Install youtube-dl"
}

_install_qemu ()
{
	this_machine=`uname -m`
	[ "$this_machine" != "x86_64" ] && _notify_when_done 1 "Install qemu" "Currently I support only x86_64 systems" && return
	echo "Need to install qemu for x86_64 architecture.. But there's a whole bunch of dependencies/subdependencies to be installed first."
	echo "Installing dependencies: qemu-kvm qemu-system-x86 virt-manager virt-viewer libvirt-bin"
	sudo apt-get install -y qemu-kvm qemu-system-x86 virt-manager virt-viewer libvirt-bin
	_notify_when_done $? "Install qemu"
}

_install_tftp_server ()
{
	echo "Installing tftp-server dependencies: xinetd tftpd tftp"
	sudo apt-get install -y xinetd tftpd tftp
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

__do_save_prev_vim ()
{
	target=$1
	if [ -d /home/$USER/$target ]; then
		echo "Any of the following can be done:"
		echo "m: Move existing $target to .my$target in home directory so that you can't lose your existing plugins/addons"
		echo "d: Remove existing $target with the risk of losing existing plugins you might have setup previously"
		echo -ne "If m|d not chosen, I may merge existing with my own c10 vim setup files"
		read -p "Your choice (m/d): " answer
		if [ "$answer" ==  "m" ]; then
			mv /home/$USER/$target /home/$USER/.my$target
		elif [ "$answer" ==  "d" ]; then
			rm -rf /home/$USER/$target
		fi
	fi
}

_install_vim ()
{
	sudo chown $USER /home/$USER/.viminfo && sudo chmod a+rw /home/$USER/.viminfo
	read -p "for VIM, c10 provides .vim and .vimrc in c10setup. The .vim and .vimrc have some plugins and keymaps which become very handy for a Vimmer. If you want them, I can place them in your HOME as .vim and .vimrc replacing existing ones. Shall I install .vim/.vimrc?(y|n): " answer
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

_install_arc_dark ()
{
	echo "I just need to add noobslab to ppa repo listing, update package list, install package 'arc-theme'.. Then you can use unity-tweak-tool to choose any theme"
	sudo add-apt-repository ppa:noobslab/themes
	_notify_when_done $? "Install dark-theme"
	sudo apt-get update
	sudo apt-get install -y arc-theme
	_notify_when_done $? "Install dark-theme"
}

_install_archive_and_unarchive_tool ()
{
	archive_tool=$(echo $1 | awk -F"_"  '{print $1}')
	unarchive_tool=$(echo $1 | awk -F"_"  '{print $2}')
	sudo apt-get install -y $archive_tool $unarchive_tool
}

declare -a must_c10utils=(vim cscope exuberant-ctags curl git at tree ifstat minicom tftp-server meld ssh p7zip-full rar_unrar zip_unzip xz-utils bzip2 lzma_unlzma compress_uncompress pdfgrep nmap vlc artha net-tools exfat-fuse exfat-utils youtube-dl texinfo manpages-posix-dev)
declare -a opt_c10utils=(dconf-editor unity-tweak-tool lftp subversion openvpn valgrind tomboy skype gparted synaptic qemu unity-dark-theme wifi-radar wireshark)

install_c10utils ()
{
	local _desc
	[ "$1" == "optional" ] && optional=1 || optional=0
	shift
	c10utils=("$@")
	if [ $optional -eq 1 ]; then
		echo -ne "Optional packages are listed below:\n${c10utils[@]}\n"
		echo "They're legit, but may be waste of disk if unwanted"
		read -p "Enter 'n' if you don't want above right now: " no
		[[ $no == "n" ]] && return 0
	fi
	declare -A _descs=( \
		["skype"]="Networking app with voice/video/messaging support" \
		["youtube-dl"]="Youtube video downloader" \
		["qemu"]="Virtual machine OS emulator for Linux" \
		["tftp-server"]="A tftp server working with xinetd" \
		["vim"]="An advanced programmer's text editor" \
		["unity-dark-theme"]="Unity theme. Light-sensitive-eye-friendly" \
		["rar_unrar"]="Compress/decompress RAR files" \
		["zip_unzip"]="Compress/decompress ZIP files" \
		["lzma_unlzma"]="Compress/decompress LZMA files" \
		["compress_uncompress"]="Compress/decompress 'COMPRESS' type files" \
		)
	for i in "${c10utils[@]}"; do
		_desc=${_descs[${i}]}
		if [ -n "${_desc}" ]; then
			# description: "tool - tool description head"
			_desc="${i} - "${_desc}
		else
			_desc=$(apt-cache search ${i} | grep "^$i ")
		fi
		do_apt_install=0
		case "$i" in
			"skype") _install_skype ;;
			"youtube-dl") _install_youtube_dl ;;
			"qemu") _install_qemu ;;
			"tftp-server") _install_tftp_server ;;
			"vim") _install_vim; do_apt_install=1 ;;
			"unity-dark-theme") _install_arc_dark ;;
			"rar_unrar"|"zip_unzip"|"lzma_unlzma"|"compress_uncompress")
				_install_archive_and_unarchive_tool $1 ;;
			*) do_apt_install=1 ;;
		esac
		if [ $do_apt_install -eq 1 ]; then
			answer="y"
			[ $gInteract -eq 1 ] && \
				echo -ne "\n\n----${_desc}\n"
				read -p "Install '$i'? (y|n): " answer
			exit_if_requested $answer
			[ "$answer" != "y" ] && continue
			echo -e "Installing $i"
			sudo apt-get install -y $i
			_notify_when_done $? "Install $i"
		fi
	done
}

declare -a c10rems=(rhythmbox brasero shotwell empathy totem thunderbird deja-dup)
uninstall_c10rems ()
{
	for i in "${c10rems[@]}"; do
		read -p "\n\n****Remove '$i'? (y|n): " answer
		[ "$answer" != "y" ] && continue
		exit_if_requested $answer
		sudo apt-get remove --purge $1 -y
		_notify_when_done $? "Uninstall $1"
	done
	sudo apt-get autoremove
	sudo apt-get autoclean
}

setup_c10bash ()
{
	local replacer="${dir_c10setup}/.c10bashsetup.sh"

	# For paths/special variables/symbols in filenames to work properly in sed -s, make them specially parse-able using '\any-special-symbol'
	replacer=$(printf '%s' "${replacer}" | sed 's/[[\.*/]/\\&/g; s/$$/\\&/; s/^^/\\&/')

	sed -i -e "s/\~\/\.bash_aliases/${replacer}/g" /home/$USER/.bashrc

	echo "Setup done for c10bash"
}

exit_if_requested ()
{
	[[ "$1" == "x" ]] && echo -e "\nExiting c10setup...\n" && exit 0
}

## Start Of Bash Script SOBASS ##

gInteract=0

# Check if this is just Usage info invocation
[ $# == 0 ] && _print_usage 1

[ "$1" == "-i" ] && gInteract=1

echo "Will do an update first to install any packages.."
sudo apt-get update
_notify_when_done $? "apt-get update"
sudo apt-get install -f
_notify_when_done $? "apt-get install -f"

echo "Installing various tools/utilities"
install_c10utils "must" "${must_c10utils[@]}"
install_c10utils "optional" "${opt_c10utils[@]}"

echo -e "Removing few tools/utilities which are not to c10's taste"
read -p "Shall we remove packages/utilities? (y|n): " answer
[[ "$answer" == "y" ]] && uninstall_c10rems
exit_if_requested $answer

echo -ne "Setup c10 bash"
setup_c10bash

echo -e "\nTata!\n"
exit 0
