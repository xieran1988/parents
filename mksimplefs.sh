#!/bin/bash

p=`pwd`
fs=$p/simplefs
cd $fs
tar -xf $p/buildroot/output/images/rootfs.tar -C $fs 
( cd etc/init.d; mv S40network K40network )
cat >> etc/init.d/rcS <<E
telnetd -l /bin/sh
#. /usr/share/ti/gst/omap3530/loadmodules.sh
(
cd /opt/3530/
grep 37X /proc/cmdline && cd /opt/3730
insmod cmemk.ko allowOverlap=1 phys_start=0x86300000 phys_end=0x87300000 \\
	        pools=1x5250000,6x829440,1x345600,1x691200,1x1
. /opt/loadmodules.sh
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

mkdir opt/3530
mkdir opt/3730
(
cd $p/emafs-3730/opt/dvsdk/omap3530
cp *.ko $fs/opt/3730
cp loadmodules.sh $fs/opt
)
cp `find $p/emafs/lib/modules/ -name *.ko` $fs/opt/3530
(
cd $p/emafs/
tar -cf - usr/share/ti/ti-codecs-server | tar -xf - -C $fs
)
#install $p/emafs-3730/opt/dvsdk/omap3530/cs.x64P
sed -i '/insmod cmemk/d' opt/loadmodules.sh

exit 0

