#!/bin/bash

fspath=`realpath $1`
awk '{print $1}' /etc/exports | grep $fspath || {
	echo "$fspath not in /etc/exports"
	echo "adding .."
	sudo sed -i "\$a$fspath *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)" /etc/exports
	sudo /etc/init.d/nfs-kernel-server restart
}

