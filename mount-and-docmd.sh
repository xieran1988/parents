#!/bin/sh

ip=$1
path=$2
shift 
shift
cd /
mount | grep "^$ip:$path" > /dev/null || {
	mount -o nolock $ip:$path root
}
cd root
echo -----------------------------
$*
echo -----------------------------

