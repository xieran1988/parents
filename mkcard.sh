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

cat > /tmp/boot.cmd <<E
setenv bootdelay 0
E
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "myscript" -d /tmp/boot.cmd /tmp/boot.scr

mount ${DRIVE}1 sd && \
cp $imgdir/u-boot.bin sd && \
cp $imgdir/MLO sd && \
cp $imgdir/uImage sd && \
sync && \
umount sd && \
sleep 10 && \
partprobe && \
mount ${DRIVE}1 sd && \
cp /tmp/boot.scr sd && \
sync && \
umount sd
