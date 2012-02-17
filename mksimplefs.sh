#!/bin/bash

p=`pwd`
fs=$p/simplefs
rm -rf $fs
mkdir $fs
cd $fs
tar -xf $p/buildroot/output/images/rootfs.tar -C $fs 
( cd etc/init.d; mv S40network K40network )
cat >> etc/init.d/rcS <<E
telnetd -l /bin/sh
#. /usr/share/ti/gst/omap3530/loadmodules.sh
(
cd opt/dvsdk/omap3530/
insmod cmemk.ko allowOverlap=1 phys_start=0x86300000 phys_end=0x87300000 \\
	        pools=1x5250000,6x829440,1x345600,1x691200,1x1
. loadmodules.sh
)
E
chmod 777 root
mkdir etc/profile.d
echo 'echo *** WELCOME ! YOU HACKIT INTO IT ! ***' > etc/profile.d/a.sh
cp $p/profile.sh etc/profile.d/b.sh
rm etc/securetty
cp $p/inittab-3530 etc/inittab
cp $p/mount-and-docmd.sh .
(
cd $p/emafs
#tar -cf - usr/share/ti/ \
#	lib/modules/ \
#	| tar -xf -C $fs
)

(
cd $p/emafs-3730
echo $fs
tar -cf - \
	opt/dvsdk/omap3530/*.sh \
	opt/dvsdk/omap3530/*.ko \
	opt/dvsdk/omap3530/cs.x64P \
	lib/modules/ \
	| tar -xf - -C $fs
)
sed -i '/insmod cmemk/d' opt/dvsdk/omap3530/loadmodules.sh

exit 0

