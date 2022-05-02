#!/bin/bash

gUsageString="Usage: $0 <args>
This script works on PWD in which it's invoked and works by taking 
each file recursively (interactively) and allow user to choose 
one of many uder-defined actions to perform on each file.
args:
-c <conf-file>   - Mandatory, specifies path/name of .conf file
                   For syntax/explanation, refer sample_filops.conf
-o               - Optional, specifies to open all files before
                   giving choice of actions to user
-s <startdir>    - Optional, specifies sub-directory name/path in PWD.
                   If provided, $0 starts work in with this startdir
                   and continues work on any subsequent folders in PWD
                   This is useful when $0 was interrupted in DIR1
                   and needed to run again but skip operating on the
                   previously worked sub-directories
                   e.g. ./sent/videos/avi
                   e.g. /home/absolute-path-to-PWD/sent/videos/avi
                   e.g. sent/videos/avi
                   NOTE: startdir name cannot start with '../'
"
#-l <leave-lvl>   - Optional, file-count if less, $0 prompts to move remaining
                   #leavel-lvl number of files to other directories and lets
						 #user decide what to do [-l support is TODO]
#-a               - Optional, indicates $0 should consider hidden files
                   #recursively, or else hidden files are not considered
                   #[-a support is TODO]

## Script actually starts executing @ SOBASS ##

## Helper bash functions ##
DisplayUsage ()
{
	local st=$1; shift 1
	[ -n "${@}" ] && echo -e "\nERROR: ${@}"
	printf "\n${gUsageString}\n"
	exit $st
}

# If user forgot cmd codes, help him remember and continue
ListCAPs ()
{
	local cmd=""
	for cmd in ${!gCAPs[@]}; do
		[ -f "${1}" -a "${cmd}" == "gc" ] && continue
		[ -d "${1}" -a "${cmd}" == "o" ] && continue
		[ $gAutoOpenFile -eq 1 -a "${cmd}" == "o" ] && continue
		echo -e "${cmd}\t- ${gCAPs[${cmd}]}"
	done
}

OpenFile ()
{
	local f="${@}"
	local finfo=$(file "${f}")
	finfo=${finfo#*${f}: }
	if [[ "${finfo,,}" =~ "text" ]]; then
		gOpener=TextOpener
	elif [[ "${finfo,,}" =~ "audio" ]]; then
		gOpener=AudioOpener
	elif [[ "${finfo,,}" =~ "media" ]]; then
		gOpener=AvOpener
	else
		gOpener=""
		echo "No app given to open ${1}" >&2 && return
	fi
	${gFileOpenerCmds[$gOpener]} ${1}
}

SkipThisEntry ()
{
	return # do nothing
}

## Global variables used to perform necessary operations ##
gCfgFile=""
gStartDir=""
gMainDir=""
gAutoOpenFile=0
gOpener=""
declare -A gCAPs
declare -A gDirStack
declare -A gFileOpenerCmds
declare -A gFileOpenerAppNames

################### START OF BASH SCRIPT (SOBASS) ###################

# Parse and validate arguments to setup environment
while [[ $# -gt 0 ]]; do
	case $1 in
		-c)
			if ([ -z "${2}" ] || [[ "${2}" != *.conf ]] || [ ! -f "${2}" ]); then
				DisplayUsage -2 "Need an existing .conf type file"
			fi
			gCfgFile="${2}"
			shift 2; # shift past arg and it's value
			;;
		-o)
			gAutoOpenFile=1
			shift; # shift past arg
			;;
		-s)
			if [ ! -d "${2}" ]; then
				DisplayUsage -3 "${2}: No such directory found in ${PWD}"
			fi
			if [ "${2}" == "../"* ]; then
				DisplayUsage -4 "${2}: ../ is not accepted as startdir"
			fi
			gStartDir="${1}"
			# Covert as absolute path
			if [ "${gStartDir:0:1}" != "/" ]; then
				if [ "${gStartDir:0:2}" == "./" ]; then
					# If it's like ./dir1/l2dir/startdir, 
					# make it as ${PWD}/dir1/l2dir/startdir
					gStartDir="${PWD}/${gStartDir:2}"
				else
					# It's got to be like dir1/l2dir/startdir
					gStartDir="${PWD}/${gStartDir}"
				fi
			fi
			shift 2; # shift past arg and it's value
			;;
		*)
			DisplayUsage -1 "Unknown argument: $1"
			;;
	esac
done

# Confirm that mandatory arguments are given
[ -z "${gCfgFile}" ] && DisplayUsage -5 "Need an existing .conf type file"

# Add SCAPs first to gCAPs (SCAPs explained in sample_filops.conf)
gCAPs["d"]='rm -rf ${f}'
gCAPs["gc"]='GoToChildDir ${f}'
gCAPs["gp"]='GoToParentDir'
gCAPs["lc"]='ListCAPs ${f} >&2'
gCAPs["ls"]='ls -la ${f} >&2'
gCAPs["o"]='OpenFile ${f}'
gCAPs["x"]='exit'
gCAPs["\0"]='SkipThisEntry'

# List cmds that don't actually act on file, but help just help/info of file
# If InfoCmd is seen, continue cmd-selection-loop to actually act on file
declare gInfoCmds=("lc" "ls" "o")

# Function to update list of file-openers
AddXcapFileOpeners ()
{
	local Opener="${1}"
	local AppName="${2}"; shift 2
	local AppCmd="${@}"
	if [ -z "$(which ${AppName})" -a ! -x "${AppName}" ]; then
		echo "ERROR: ${AppName} is neither bash-cmd nor executable-with-path"
		exit -6
	fi
	# Save app-cmd/name for later usage
	Opener=${Opener#*xcap_}
	gFileOpenerAppNames["${Opener}"]="${AppName}"
	gFileOpenerCmds["${Opener}"]="${AppCmd}"
}

# Parse key=value per line from gCfgFile
while read -r line <&3; do
	( [ -z "${line}" ] || [[ "${line:0:1}" == "#" ]] ) && continue
	#echo "${line%%=*} = ${line#*=}"
	cmd="${line%%=*}"
	case ${cmd} in
		"xcap_AvOpener"|"xcap_AudioOpener"|"xcap_TextOpener")
			AppCmd=${line#*=}; AppName=${AppCmd%% *}
			AddXcapFileOpeners ${cmd} ${AppName} ${AppCmd}
			;;
		*)
			gCAPs["${line%%=*}"]="${line#*=}"
			;;
	esac
done 3<${gCfgFile}

gMainDir=${PWD}

FindStartDir ()
{
	# 'f' is guaranteed to be a directory
	local f="${@}"
	echo "** $0 ${f}:${gStartDir};"
	if [ "${gStartDir}" == "${f}" ]; then
		# found startdir, let filops start!
		gStartDir=""
		return 0
	elif [[ "${gStartDir}" =~ "${f}" ]]; then
		# startdir can be a grand-child of 'f'
		SeepIn "${f}"
	fi
	return 1
}

# Return 0 after acting (or skipping) on this file
# Return 1 if user wanted to goto parent directory
DoFilopsOnFile ()
{
	local ret=0
	local f="${@}"
	[ $gAutoOpenFile -eq 1 -a ! -d "${f}" ] && OpenFile ${f} &
	# Loop to get a valid command and act on it. Break loop -
	# 1. if SCAP is handled (OR) 2. after proper execution of UCAP
	[ -d "${f}" ] && type="dir" || type="file"
	while true; do
		read -p "Action for $type ${f}: " cmd
		echo "Cmd given:: $cmd" >&2
		[ -n "$cmd" ] && echo "Action: ${gCAPs[$cmd]}" >&2
		case "${cmd}" in
			"d"|"lc"|"ls"|"x") # Handle simple SCAPs here
				eval "${gCAPs[$cmd]}"
				# Break cmd-loop only if current cmd is an InfoCmd
				echo "cmd: $cmd;; is in ${gInfoCmds[@]}?" >&2
				[[ " ${gInfoCmds[@]} " =~ " ${cmd} " ]] || break
				;;
			"gc") # User wants to do filops in this child directory
				if [ -d "${f}" ]; then
					SeepIn filops "${f}"
					break
				fi
				echo "${f} is not a directory!" >&2
				;;
			"gp") # try to return to previous SeepIn on recursion-stack
				ret=1
				break
				;;
			"") # User doesn't want to act on this file, skip it
				break
				;;
			"o") # Ensure to open file if possible and if not already open
				if [ $gAutoOpenFile -eq 1 -a "$(pgrep ${gAppName})" ]; then
					echo "${f} is already open" >&2 && continue
				fi
				[ -d "${f}" ] && echo "${f} is a directory" >&2 && continue
				OpenFile "${f}"
				;;
			*) # Handle all UCAPs here
				if [[ " ${!gCAPs[@]} " =~ " $cmd " ]]; then
					# ${f} is in UCAP action string, don't give it as action arg
					eval "${gCAPs[$cmd]}"
					break
				fi
				echo -e "Unknown cmd: $cmd\nValid cmds: ${!gCAPs[@]}" >&2
				;;
		esac
	done
	pkill ${gFileOpenerAppNames[$gOpener]}
	echo $ret
}

# Seep in through all directories in PWD recursively
# to list and let user act on files as required
# Usage: SeepIn <filops|cleanup> "path-to-dir"
#        filops  - filops to act on files as per user choice
#        cleanup - removes empty directories recursively,
#                  called after filops completes
SeepIn ()
{
	local f
	local SeepOpt=$1
	shift 1
	local dir="${@}"
	for f in "${dir}"/*; do
		echo "--- Seep Entry: ${f}"
		# If startdir is specified, skip all child/sub-child
		# directories recursively till we find gStartDir
		[ -d "${f}" -a -n "${gStartDir}" ] && (FindStartDir "${f}" || continue)
		case "$SeepOpt" in
			filops)
				echo "+++ filops on ${f}"
				[ $(DoFilopsOnFile "${f}") -eq 1 ] && return 1
				;;
			cleanup)
				[ ! -d "${f}" ] && continue
				[ $(ls -A "$1" | wc -l) -gt 0 ] && continue
				read -p "Remove empty dir ${f}? (y|n): " ok
				[ "$ok" == "y" ] && rmdir "$1"
				;;
			*) echo "ERROR: Something went bad! Exiting.."; exit -7
				;;
		esac
	done
}

BakStartDir="${gStartDir}"

SeepIn filops "${gMainDir}"

read -p "Empty directories maybe leftover, enter 'y' to remove them: " ok
if [ "$ok" == "y" ]; then
	gStartDir="${BakStartDir}"
	SeepIn cleanup "${gMainDir}"
fi

#shopt -s nullglob dotglob     # To include hidden files
exit 0
