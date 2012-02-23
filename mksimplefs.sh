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
grep 37X /proc/cmdline && { 
	echo boot 3730
	cd /opt/3730
	#insmod cmemk.ko phys_start=0x86300000 phys_end=0x87300000 \\
	#        pools=1x5250000,6x829440,1x345600,1x691200,1x1
	#insmod cmemk.ko phys_start=0x86300000 phys_end=0x87300000 \\
	#        pools=1x5250000,6x829440,1x345600,1x691200,1x1
	insmod cmemk.ko phys_start=0x86300000 phys_end=0x87200000 pools=1x3000000,1x1429440,6x1048576,4x829440,1x327680,1x256000,7x131072,20x4096 allowOverlap=1
	#insmod cmemk.ko phys_start=0x86300000 phys_end=0x87200000 pools=1x3000000,1x1429440,6x1048576,3x1843200,1x327680,1x256000,7x131072,20x4096 allowOverlap=1
# 0x80000000     99 MB  Linux
# 0x86300000     15 MB  CMEM
# 0x87200000     13 MB  CODEC SERVER
	rm -f /dev/cmem
	mknod /dev/cmem c \`awk '\$2=="cmem" {print \$1}' /proc/devices\` 0
} 
grep 35X /proc/cmdline && {
	echo boot 3530
	cd /opt/3530/
	insmod cmemk.ko allowOverlap=1 phys_start=0x86300000 phys_end=0x87300000 \\
	        pools=1x5250000,6x829440,1x345600,1x691200,1x1
}
# 0x80000000     99 MB  Linux
# 0x86300000     15 MB  CMEM
# 0x87200000     13 MB  CODEC SERVER
insmod dsplinkk.ko
rm -f /dev/dsplink
mknod /dev/dsplink c \`awk '\$2=="dsplink" {print \$1}' /proc/devices\` 0
insmod lpm_omap3530.ko
mknod /dev/lpm0 c \`awk '\$2~"lpm" {print \$1}' /proc/devices\` 0
insmod sdmak.ko
mknod /dev/video0 c 81 0

mkdir /dev/snd
cd /sys/class/sound
for i in control* pcm* mixer timer; do
	mknod /dev/snd/\$i c \`cat \$i/dev | sed "s/:/ /"\`
done
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
#cp $p/emafs-3730/opt/dvsdk/omap3530/cs.x64P $fs/usr/share/ti/ti-codecs-server
sed -i '/insmod cmemk/d' opt/loadmodules.sh

exit 0

