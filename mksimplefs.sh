#!/bin/bash

. profile.sh

p=`pwd`
fs=$p/simplefs
cd $fs
tar -xf $p/buildroot/output/images/rootfs.tar -C $fs 
( cd etc/init.d; mv S40network K40network )

{ 
	cat $p/profile.sh 
	echo export parentsdir=$parentsdir
} > etc/host-profile.sh
cp $p/rcS.sh etc/init.d/rcS

for i in $proj; do 
	mkdir root/$i
	make -C $p/$i clean
	make -C $p/$i 
	make -C $p/$i cp-release-files c=`pwd`/root/$i
done

chmod 777 root
mkdir etc/profile.d
echo 'echo *** WELCOME ! YOU HACKIT INTO IT ! ***' > etc/profile.d/a.sh
rm etc/securetty
cp $p/inittab-3530 etc/inittab
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

