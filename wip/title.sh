#!/bin/bash

_c10t () {
	[[ -z "$1" ]] && return
	[[ -z "$ORIG" ]] && ORIG="$PS1"
	TITLE="\[\e]2;$*\a\]"
	PS1="${ORIG}${TITLE}"
}

#_c10t $1

[[ -z "$1" ]] && return
[[ -z "$ORIG" ]] && ORIG="$PS1"
export TITLE="\[\e]2;$*\a\]"
export PS1="${ORIG}${TITLE}"
