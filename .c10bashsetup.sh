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

# subversion editor setting
export SVN_EDITOR=vim

# bash default editor setting
export EDITOR=vim

# key-map to invoke "vim ."
bind -x '"\C-o":"vim ."'

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
alias detag='rm -rf tags cscope.out ncscope.out ctags.files cscope.files'
alias retag.sh="${c10dir}/retag.sh"

# Git specific - Oh we use them alot! #
alias gitst='git status'
alias gitm='git checkout master'
alias gitc='git checkout'
alias gitp='git pull'
alias gitd='git diff'
alias gitl='git log'
alias gitb='git branch'
alias gitlog="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# For better color-coding and visibility of 'ls' output contents #
export LS_COLORS="$LS_COLORS:ow=30;42:tw=30;42:";

# ls display file size as human-readable size
alias lh='ls -lh'

# Various handy scripts
alias lpmode.sh="${c10dir}/lpmode.sh"
alias packit.sh="${c10dir}/packit.sh"
alias unpack.sh="${c10dir}/unpack.sh"
alias pbar.sh="${c10dir}/pbar.sh"
alias ydl.sh="${c10dir}/ydl.sh"
alias devimpro.sh="${c10dir}/devimpro.sh"

# Try including bash settings from a local file, if it exists.
# This way we can make sure the project/confidential work specific
# environment/aliases without having to commit those details to git
if [ -f ~/.c10bashsetup_local.sh ]; then
	. ~/.c10bashsetup_local.sh
fi
