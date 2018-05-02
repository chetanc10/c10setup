#!/bin/bash

echo "Hello! I'm an Interactive Installer Program for basic system utilities and libraries. Enter 'x' during any stage of questioning from me to kill me"
echo "Entering 'n' or just pressing <ENTER> will be considered as choice for 'NO' ;-)"

invoked=$0

dir_c10setup=`dirname $invoked`
[ "$dir_c10setup" == "." ] && dir_c10setup=$PWD

sound_success=/usr/share/sounds/freedesktop/stereo/complete.oga
sound_failure=/usr/share/sounds/freedesktop/stereo/suspend-error.oga

alert_sel="z"

__alert_func () {
	if [ "$alert_sel" == "z" ]; then
		zenity --info --text="$1" 2>/dev/null
	else # no zenity, just echo on terminal
		echo "$1"
	fi
}

# Invocation: _notify_when_done <$? or other status value> <package-name> <description or extra messages>
_notify_when_done () {
	if [ "$1" == "0" ]; then # Success case
		[ -e $sound_success ] && paplay $sound_success &
		__alert_func "$2: SUCCESS"
	else # Failure case
		[ -e $sound_failure ] && paplay $sound_failure &
		__alert_func "$2: FAILURE\nReason: $3"
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

declare -a cutils=(vim cscope exuberant-ctags curl git at tree ifstat dconf-editor unity-tweak-tool valgrind minicom tftp-server lftp subversion meld ssh rar unrar openvpn vlc tomboy nmap artha skype youtube-dl gparted synaptic wifi-radar wireshark qemu unity-dark-theme)

install_cutils () {
	for i in "${cutils[@]}"
	do
		echo -ne "\n\n****Install '$i'?(y|n): "
		read answer
		if [ "$answer" == "y" ]; then
			# This case block handles normal installables and also special utilities/apps which are not simple/proper apt-get installables
			do_aptget_install=0
			case "$i" in
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
				echo -e "Installing $i"
				sudo apt-get install $i
				_notify_when_done $? "Install $i"
			fi
		fi
		exit_if_requested $answer
	done
}

declare -a clibs=(libpcap-dev libncurses5-dev libelf-dev libssl-dev ffmpeg libav-tools x264 x265)

install_clibs () {
	for i in "${clibs[@]}"
	do
		echo -ne "\n\n****Install '$i'?(y|n): "
		read answer
		if [ "$answer" == "y" ]; then
			echo -e "Installing $i"
			sudo apt-get install $i
			_notify_when_done $? "Install $i"
		fi
		exit_if_requested $answer
	done
}

install_c10scripts () {
	echo "I'll just setup a soft link for all the requested scripts. So you MUST keep this folder in this directory or move it somewhere else and invoke from that directory"
	echo "Everytime you move this directory, you'll need to run c10setup.sh from the new path so that the soft-links are not broken.. I warned ya!"
	local filename
	for file in "$dir_c10setup"/*.*
	do
		filename=$(basename $file)
		[ "$filename" == "README.md" ] && continue;
		[ "$filename" == "c10setup.sh" ] && echo "I'll not setup soft-link for c10setup.sh as it may break if this folder moves and you shouldn't be relying only on c10setup softlink" && continue;
		echo -ne "\n\n****Install '$filename'?(y|n): "
		read answer
		if [ "$answer" == "y" ]; then 
			sudo ln -s "$file" /bin/$filename
			_notify_when_done $? "Install $i"
		fi
		exit_if_requested $answer
	done
}

declare -a crems=(rhythmbox brasero shotwell empathy totem)

install_crems () {
	for i in "${crems[@]}"
	do
		echo -ne "\n\n****Remove '$i'?(y|n): "
		read answer
		if [ "$answer" == "y" ]; then
			sudo apt-get remove --purge $i
			_notify_when_done $? "Uninstall $i"
		fi
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

echo "First decide if you want GUI alerts on utility/lib/etc setup completion or just echo on terminal"
echo -ne "zenity or echo? (z/e): "
read alert_sel
echo "alert_sel: $alert_sel"
[ "$alert_sel" != "z" ] && [ "$alert_sel" != "e" ] && echo "Go learn some ABCs.. See ya later!" && exit 0

echo -ne "\nTrying to install normal updates/dependencies. Shall I proceed?(y|n): "
read answer
if [ "$answer" == "y" ]; then
	sudo apt-get update
	sudo apt-get install -f
fi
exit_if_requested $answer

echo -ne "\nTrying to install basic important libs, manpages, etc. Shall I proceed?(y|n): "
read answer
# Revisit if we find that the following's going to become a list of libs/stuffs/etc
if [ "$answer" == "y" ]; then
	sudo apt-get install manpages-posix-dev
	_notify_when_done 1 "Install manpages-posix-dev"
fi
exit_if_requested $answer

echo -ne "\nDo you need utility Installations? (y|n): "
read answer
[[ "$answer" == "y" ]] && install_cutils
exit_if_requested $answer

echo -ne "\nProceed to lib Installations? (y|n): "
read answer
[[ "$answer" == "y" ]] && install_clibs
exit_if_requested $answer

echo -ne "\nProceed to add c10 scripts to filesystem? (y|n): "
read answer
[[ "$answer" == "y" ]] && install_c10scripts
exit_if_requested $answer

echo -e "\n***************************BEWARE***************************\nDURING UNINSTALLATIONS, PLEASE BE VERY CAREFUL AND OBSERVE WHICH PACKAGES ARE ADDITIONALLY REMOVED ALONG WITH REQUESTED UNINSTALLATION AND DECIDE IF YOU WANT TO PROCEED! OTHERWISE, KEEP AWAY!"
echo -ne "Proceed to UNInstallations? (y|n): "
read answer
[[ "$answer" == "y" ]] && install_crems
exit_if_requested $answer

echo -ne "\nSetup c10bash? (y/n): "
read answer
[[ "$answer" == "y" ]] && setup_c10bash
exit_if_requested $answer

echo -e "\nTata..!\n"
