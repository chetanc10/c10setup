#!/bin/bash

# Kill all processes which are not to be run in low power mode (lpmode)

echo "killing processes.."
killall artha 2>/dev/null && echo "artha"
killall tomboy 2>/dev/null && echo "tomboy"
killall xpad 2>/dev/null && echo "xpad"
killall dropbox 2>/dev/null && echo "dropbox"
echo "Killing sshd and ssh-agent. Restart them by: sudo service sshd start && sudo ssh-agent"
service stop sshd 2>/dev/null && echo "sshd"
killall ssh-agent 2>/dev/null && echo "ssh-agent"
