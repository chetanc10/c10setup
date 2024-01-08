# !/bin/bash

## my bash setup/definitions ##
# Just to make it easier to use terminal command line 
# for helping make developer environment effective the following's done!

# See /usr/share/doc/bash-doc/examples in the bash-doc package.

# Improve history file storage capability
unset HISTSIZE
unset HISTFILESIZE
HISTSIZE=5000
HISTFILESIZE=10000

# Disable bell sound from 'less' and it's associated/wrapper cmds (like 'man')
export LESS="$LESS -Q"

# subversion editor setting
export SVN_EDITOR=vim

# bash default editor setting
export EDITOR=vim

# key-map to invoke "vim ."
bind -x '"\C-o":"vim ."'

# Deduplicate ~/.bash_history per session in background!
(tac ~/.bash_history | awk '!visited[$0]++' | tac > nbh; mv nbh ~/.bash_history) &

# Simplify normal user prompt string
PROMPT_COMMAND='echo -ne "\033]0;${PWD}\007"'
PS1='${debian_chroot:+($debian_chroot)}\W\$ '

# function to set terminal title
function c10t() {
	[[ -z "$1" ]] && return
	[[ -z "$ORIG" ]] && ORIG="$PS1"
	TITLE="\[\e]2;$*\a\]"
	PS1="${ORIG}${TITLE}"
}

##### Now the bash aliases #####

# source code browsing #
alias detag='rm -rf tags cscope.out ncscope.out ctags.files cscope.files .excludes'
alias retag="${c10s}/retag.sh"

# Git specific - Oh we use them alot! #
alias gitst='git status'
alias gitc='git checkout'
alias gitcfg='LESS=-eFRX git config -l'
alias gitp='git pull'
alias gitd='LESS=-eFRX git diff'
alias gitb='LESS=-eFRX git branch'
alias gitr='LESS=-eFRX git remote -v'
alias gitl="LESS=-eFRX git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gitlog='LESS=-eFRX git log'
alias gitblame="${c10s}/gitblame.sh"
gclone ()
{
	if [ -z "$1" ]; then
		echo "Usage: gclone <repo-url+optional-branch-references>"
		echo "gclone is same as git clone, but additionally -"
		echo "1. Asks and sets up user.name and user.email for git config"
		echo "2. Sets git config to use current branch on 'git push' automatically"
		return -121
	fi
	local args="${@}"
	local url=""
	while [[ $# -gt 0 ]]; do
		case "${1}" in
			https://*|git@*|ssh://*) url="${1}"; break ;;
			*) shift ;;
		esac
	done
	if [ -z "${url}" ]; then
		echo "Couldn't determine repo url with https or ssh"
		return 0
	fi
	git clone "${@}" || return -1
	name=$(basename "${url}"); name=$(echo $name | awk -F. '{print $1}')
	cd $name
	git config push.default current
	echo "Enter git user name and email for this git repo config."
	echo "If name or email config is not wanted, just press <ENTER>"
	read -p "user.name  : " un
	[ -n "$un" ] && git config user.name "${un}"
	read -p "user.email : " ue
	[ -n "$ue" ] && git config user.email "${ue}"
	cd ..
}
export -f gclone

# For better color-coding and visibility of 'ls' output contents #
export LS_COLORS="$LS_COLORS:ow=30;42:tw=30;42:";

# ls display file size as human-readable size
alias lh='ls -lh'

# Various handy scripts
alias lpmode="${c10s}/lpmode.sh"
alias packit="${c10s}/packit.sh"
alias unpack="${c10s}/unpack.sh"
alias pbar="${c10s}/pbar.sh"
alias ydl="${c10s}/ydl.sh"
alias devimpro="${c10s}/devimpro.sh"
alias gitmod="${c10s}/gitmod.sh"

# This is for gnu-screen based remote-ssh dev users
# This screen-block does the following:
#    1. Binds 'Esc+x' key-combo to help invoke screen from non-screen bash
#    2. Copies/appends $c10s/screenrc contents to ~/.screenrc
#       These are customizations of screen key-bindings, behavior, navigation, etc
#    2. Forces default shell startup in screen window always (can be exited by ctrl-d).
#       To DISABLE screen auto-launch per each bash session, do the following:
#       $ touch $c10s/disable-c10-gnu-screen
#       If enabled, Screen can be either:
#         a. a first-available prev detached-screen session, re-attached automatically OR
#         b. a new screen session if there's no prev detached screen session
if [ ! -f $c10s/disable-c10-gnu-screen ]; then
	wscreen () {
		screen -ls >/dev/null && screen -RR || screen
	}
	if [ -z "$STY" ]; then
		# Shortcut 'Esc+x' to launch screen
		bind -x '"\ex":"wscreen"'
		# Ensure c10-screenrc is sourced in default ~/.screenrc
		if [ ! -f ~/.screenrc ] || \
			[ -z "$(grep -F "source $c10s/c10-screenrc" ~/.screenrc 2>/dev/null)" ]; then
			echo "source $c10s/c10-screenrc" >> ~/.screenrc
		fi
		# If there's any prev detached screen session, attach it
		# Else, start a fresh screen session
		wscreen
	else
		# bash started in screen, 'reset' tty to fix input/output issue
		reset
	fi
fi

# Try including bash settings from a local file, if it exists.
# This way we can make sure the project/confidential work specific
# environment/aliases without having to commit those details to git
if [ -f ~/.c10bashsetup_local.sh ]; then
	. ~/.c10bashsetup_local.sh
fi
