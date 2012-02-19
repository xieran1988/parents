#!/bin/bash

fs=$1
cd $fs
sed -i '/wait/s/^/#/' etc/inittab
#sed -i '/si::sysinit/s/^/#/' etc/inittab
cat > etc/init.d/rcS <<E
mount -t proc proc /proc
mount -o remount,rw /
mkdir -p /dev/pts
mkdir -p /dev/shm
mount -a
telnetd -l /bin/sh
cd /opt/dvsdk
#insmod cmemk.ko phys_start=0x85000000 phys_end=0x86000000 pools=20x4096,10x131072,2x1048576
#insmod cmemk.ko phys_start=0x8f000000 phys_end=0x90000000 pools=20x4096,10x131072,2x1048576
insmod cmemk.ko phys_start=0x86300000 phys_end=0x87300000 \\
	        pools=1x5250000,6x829440,1x345600,1x691200,1x1
E
sed -i 's/ttyO0/ttyS0/' etc/inittab
sed -i 's/id:5/id:3/' etc/inittab
( cd bin; ln -sf busybox login )
mkdir opt/dvsdk
cp ../emafs-3730/opt/dvsdk/omap3530/*.ko opt/dvsdk
exit 0

