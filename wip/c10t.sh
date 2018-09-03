# !/bin/bash

# script used to set terminal title

[[ -z "$1" ]] && return
[[ -z "$ORIG" ]] && ORIG="$PS1"
export TITLE="\[\e]2;$*\a\]"
export PS1="${ORIG}${TITLE}"

