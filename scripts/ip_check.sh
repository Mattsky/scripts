#!/bin/bash

# Script to poll tons of systems for IP addresses and drop them
# into a .csv file for reference.
# Note: depends on keybased SSH.

# enable cancellation of individual systems if they don't connect properly

trap ctrl_c INT

function ctrl_c() {
	echo "** Trapped CTRL-C"
}

echo "Hostname , IP address" > ~/address_list.txt

while read -r line || [[ -n $line ]]; do
	echo "Connecting to $line"
	# -n flag makes sure stdin doesn't get eaten and break the loop!
	RESULTS=$(ssh -n $line "/sbin/ifconfig | grep 'inet addr' | grep -v '127.0.0.1' | awk '{print \$2}' | sed 's/addr\://'")
	echo "Exit code: $?"
	if [ $? -eq 0 ]; then
		echo "$line , $RESULTS" >> ~/address_list.txt	
	fi
done < "$1"
