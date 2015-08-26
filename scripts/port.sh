#!/bin/bash
#
# Purpose: script to ease adding ports to iptables for KVM guest NATting.
#
# Author: Matt N
# Date: 26/8/2015
# Version: 0.1

usage(){
        echo "Usage: port.sh <protocol> <host external port> <guest port> <guest ip>"
        exit 1
}

[[ $# -eq 0 ]] && usage

proto=$1
extport=$2
intport=$3
guestip=$4

/sbin/iptables -t nat -A PREROUTING -p $proto --dport $extport -j DNAT --to $guestip:$intport
/sbin/iptables -I FORWARD -d $guestip/32 -p $proto -m $proto --dport $intport -j ACCEPT
/sbin/service iptables save
