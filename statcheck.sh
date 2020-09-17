#!/bin/bash

########################### GENERIC REUSABLE BASH FUNCTIONS (GENBASHFUNC) ###########################
# Bash functions under GENBASHFUNC are resusable functions, not specific to any build/task #

# Asynchronous notifier to alert user after a task is done, usually for long-running tasks
# with zenity and paplay if supported by Build-Host system
# Usage  : AsyncNotifyFn <ExecStatus> <CmdString>
#          <ExecStatus> = 0 for success
#                       = non-zero for failure/error
#          <CmdString>  = String explaining the task or actual command with arguments
AsyncNotifyFn ()
{
	ExecStatus=$1; shift #skip and move on to next function argument
	CmdString=${@}
	if [ -x "/usr/bin/zenity" ]; then
		[ $ExecStatus -eq 0 ] && StatStr="SUCCESS" || StatStr="FAILURE"
		zenity --info --text="$StatStr: \'${CmdString}\'" 2>/dev/null &
	fi
	if [ -x "/usr/bin/paplay" ]; then
		[ $ExecStatus -eq 0 ] && PaplayAlert="complete" || PaplayAlert="suspend-error"
		paplay /usr/share/sounds/freedesktop/stereo/${PaplayAlert}.oga 2>/dev/null &
	fi
}

# ACTIONFLAGS: Action Flags used by ShowRunCmdFn/CheckStatusFn individually or combined
# Bit to display just a warning on error/failure without exiting, success means nothing
AF_WOE=1
# Bit to display message on success; on failure default behaviour invoked - exit!
AF_DS=2
# Bits to display message on success and display warning on error/failure without exiting
AF_DSWOE=3

# Check Status function to display error/success message and/or exit as per user choice
# Usage  : CheckStatusFn <ExecStatus> <ActionFlag> <CmdString>
#          <ExecStatus>  = $? for previous command execution status
#                        = integer, specific to use-case
#          <ActionFlag>  = 0 - if we need to exit on Error/Failure and no message display on success
#                        = non-zero flags (refer ACTIONFLAGS for all other possible values)
#          <CmdString>   = String explaining the task or actual command with arguments
# Return : none
CheckStatusFn ()
{
	ExecStatus=$1; shift #skip and move on to next function argument
	ActionFlag=$1; shift #skip and move on to next function argument
	CmdString=${@}
	if [ $ExecStatus -ne 0 ]; then
		(( $ActionFlag & $AF_WOE )) && StatTitleStr=ERROR || StatTitleStr=WARNING
		echo -e "\n******************************$StatTitleStr******************************"
		echo -e "${CmdString}\n"
		AsyncNotifyFn $ExecStatus ${CmdString}
		if (( $ActionFlag ^ $AF_WOE )); then
			if [ "${gLogFile}" ]; then
				echo -e "Please check the log-file: ${gLogFile}"
				echo -e "Backup ${gLogFile} if required as next build overwrites current contents"
			fi
			echo -e "Exiting..\n" && exit $ExecStatus
		fi
	elif (( $ActionFlag & $AF_DS )); then
		echo -e "\n******************************SUCCESS******************************"
		echo -e "${CmdString}\n"
		AsyncNotifyFn 0 ${CmdString}
	fi
}

gLearnerMode=1

# Function to display and run any given command with arguments
# Usage  : ShowRunCmdFn <ActionFlag> <CommandWithArguments>
#          <ActionFlag> = 0 - if we need to exit on Error/Failure and no message display on success
#                       = non-zero flags (refer ACTIONFLAGS for all other possible values)
#          <CmdString>  = Command String with arguments
#          Following notifies of failure and exits if extracting some_package fails
#          e.g. ShowRunCmdFn 0 tar -xf some_package.tar
#          Following notifies of failure but doesn't exit; consider this as warning of failure
#          e.g. ShowRunCmdFn AF_WOE ls /home/somepath/WE866C3.tar
# Return : none
ShowRunCmdFn ()
{
	ActionFlag=$1; shift #skip and move on to next function argument
	echo -e "\n"${@}"\n"
	[ $gLearnerMode -eq 1 ] && echo "Press ENTER to execute above command.." && read okay
	"$@"
	CheckStatusFn $? $ActionFlag "$@"
}

DotConfigFile=111

ShowRunCmdFn AF_DSWOE sed -i 's/# CONFIG_WIRELESS is not set/CONFIG_WIRELESS=y/' ${DotConfigFile}
#ShowRunCmdFn 1 make zImage
