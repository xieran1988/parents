#!/bin/bash

fs=simplefs
mkdir $fs
tar -xf buildroot/output/images/rootfs.tar -C $fs 
cd $fs/etc/init.d
mv S40network K40network
cd ../..
sed -i '$atelnetd -l /bin/sh' etc/init.d/rcS 
sed -i '$amount ' etc/init.d/rcS 
chmod 777 root
mkdir etc/profile.d
echo 'echo *** WELCOME ! YOU HACKIT INTO IT ! ***' > etc/profile.d/a.sh
rm etc/securetty
cp ../inittab-3530 etc/inittab
cp ../dvsdk-3530/gstreamer-ti_svnr884/src/.libs/libgstticodecplugin.so usr/lib/gstreamer-0.10
cp ../mount-and-docmd.sh .
cd ..
{
	cd emafs
	tar -cf /tmp/ti.tar \
		usr/share/ti/ \
		lib/modules/ 
	cd ../simplefs
	tar -xf /tmp/ti.tar 
	sed -i '$a. /usr/share/ti/gst/omap3530/loadmodules.sh' etc/init.d/rcS 
}
cd ..

exit 0

