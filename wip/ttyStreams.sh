#!/bin/bash

set -eu
#set -x
#set -v
set -o pipefail

RunIt()
{
    local InCmd="$1" OutCmd="$2"
    local result
    local prompt=$(printf "Please input test parameters\n> ")

    while read -p "$prompt" -e COMMAND; do
        echo "/tmp/myftm $COMMAND" | empty -s -o "$OutCmd"
        empty -w -i "$InCmd" -o "$OutCmd" "0 #" "" " #" "" || result=$?
        if [ "$result" -eq 1 ]; then
            echo OK
        elif [ "$result" -eq 255 ]; then
            echo Timeout
        else
            echo Error
        fi
    done;
    exit
}

link="/tmp/StreamLink"
if [ -d "$link" -a -p "$link/in" -a -p "$link/out" ] &&
    echo "Trying to synchronize with ADB" &&
    empty -s -o "$link/out" "\n" &&
    (empty -w -i "$link/in" -o "$link/out" "0 #" || [ $? -eq 1 ]) ; then

    RunIt "$link/in" "$link/out"
    exit
else
    if [ -r "$link/pid" ]; then
        echo "Killing the unresponsive ADB bridge"
        empty -k "$(cat "$link/pid")"
        rm -f "$link"
    fi
fi


LinkDir="/tmp/StreamLink.$$"
InStream="$LinkDir/in"
OutStream="$LinkDir/out"
PID="$LinkDir/pid"
LOG="$LinkDir/log"
MainDir="$LinkDir"
export MainDir


mkdir -p "$LinkDir"
mkdir -p "$LinkDir/.android"
echo "0x1bc7" > "$LinkDir/.android/adb_usb.ini"

echo "Starting modem"
rfkill unblock wwan

echo "Waiting for the USB link"
while ! [ -r /dev/ttyUSB0 ]; do sleep 1; done

# OutStream and InStream are reversed in the f(ork) case
empty -f -i "$OutStream" -o "$InStream" -L "$LOG" -p "$PID" adb shell

echo "Starting ADB"
# w(ait) before sending login & password
empty -w -i "$InStream" -o "$OutStream" -t 30 "login:" "root\n" || [ $? -eq 1 ]
empty -w -i "$InStream" -o "$OutStream" "Password:" "oelinux123\n" || [ $? -eq 1 ]
echo "PS1='\$? #'" | empty -s -o "$OutStream"
empty -w -i "$InStream" -o "$OutStream" "0 #" "mkdir -p /cache/firmware\n" || [ $? -eq 1 ]
empty -w -i "$InStream" -o "$OutStream" "0 #" || [ $? -eq 1 ]


echo "Loading the test mode binaries"
# Send the WiFi certification binaries with adb push
WIFI_BINS="athwlan.bin bdwlan.bin qwlan.bin otp.bin utf.bin"

for BIN in $WIFI_BINS; do
    adb push "$BIN" /cache/firmware 2>/dev/null
done

# Configure the kernel firmware lookup path
empty -s -o "$OutStream" "echo -n /cache/firmware > /sys/module/firmware_class/parameters/path\n"
empty -w -i "$InStream" -o "$OutStream" "0 #" || [ $? -eq 1 ]

echo "Loading the kernel module"
# Load the kernel module with the certification option
empty -s -o "$OutStream" "[ \$(cat /sys/module/wlan/parameters/con_mode) = 5 ] || insmod /usr/lib/modules/\$(uname -r)/extra/wlan.ko con_mode=5\n"
empty -w -i "$InStream" -o "$OutStream" "0 #" || [ $? -eq 1 ]

echo "Loading the test mode program"
adb push myftm /tmp/myftm 2>/dev/null

ln -f -s -n "$LinkDir" "$link"

RunIt "$InStream" "$OutStream"
