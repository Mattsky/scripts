#!/bin/bash

# Script to poll tons of systems for OpenSSL versions and dump
# affected versions into a file for reference.
# Note: depends on keybased SSH.


# Versions affected: 1.0.1 & 1.0.2

trap ctrl_c INT

function ctrl_c() {
	echo "** Trapped CTRL-C"
}

echo "Affected systems:" > ~/vulnlist.txt

while read -r line || [[ -n $line ]]; do
	echo "Connecting to $line"
	# -n flag makes sure stdin doesn't get eaten and break the loop!
	RESULTS=$(ssh -n $line "rpm -qa | grep openssl | grep '1.0.[1-2]'")
	echo "Exit code: $?"
	if [ $? -eq 0 ]; then
		echo "$line $RESULTS" >> ~/vulnlist.txt	
	fi
done < "$1"
