#! /bin/sh
# mkcard.sh v0.4
# (c) Copyright 2009 Graeme Gregory <dp@xora.org.uk>
# Licensed under terms of GPLv2
#
# Parts of the procudure base on the work of Denys Dmytriyenko
# http://wiki.omap.com/index.php/MMC_Boot_Format

LC_ALL=C

if [ $# -ne 1 ]; then
	echo "Usage: $0 <drive>"
	exit 1;
fi

DRIVE=$1
SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`

echo DISK SIZE - $SIZE bytes
if [ "$SIZE" != "1948254208" ] ; then 
	echo invalid sdcard
	exit 1
fi

dd if=/dev/zero of=$DRIVE bs=1024 count=1024

CYLINDERS=`echo $SIZE/255/63/512 | bc`

echo CYLINDERS - $CYLINDERS

{
echo ,9,0x0C,*
echo ,,,-
} | sfdisk -D -H 255 -S 63 -C $CYLINDERS $DRIVE

if [ -b ${DRIVE}1 ]; then
	mkfs.vfat -F 32 -n "boot" ${DRIVE}1
else
	if [ -b ${DRIVE}p1 ]; then
		mkfs.vfat -F 32 -n "boot" ${DRIVE}p1
	else
		echo "Cant find boot partition in /dev"
	fi
fi

if [ -b ${DRIVE}2 ]; then
	echo mk2efs
#	mke2fs -j -L "rootfs" ${DRIVE}2
else
	if [ -b ${DRIVE}p2 ]; then
		echo mk2efs
#		mke2fs -j -L "rootfs" ${DRIVE}p2
	else
		echo "Cant find rootfs partition in /dev"
	fi
fi

mkdir -p /tmp/boot && \
mount ${DRIVE}1 /tmp/boot && \
cp -v $imgdir/u-boot.bin /tmp/boot && \
cp -v $imgdir/MLO /tmp/boot && \
cp -v $imgdir/uImage /tmp/boot && \
sync && \
umount /tmp/boot && \
rmdir /tmp/boot

