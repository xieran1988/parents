fs=simplefs
rm -rf $fs
mkdir $fs
tar -xvf buildroot/output/images/rootfs.tar -C $fs 
cd $fs/etc/init.d
mv S40network K40network
cd ../..
sed -i '$atelnetd -l /bin/sh' etc/init.d/rcS 
sed -i '$amount ' etc/init.d/rcS 
chmod 777 root
mkdir etc/profile.d
echo 'echo fuck boss yang' > etc/profile.d/a.sh
rm etc/securetty
cp ../inittab-$mod etc/inittab
cd ..
[ $mod = '8168' ] && {
	tar -xvf libncurses.tar -C $fs
	tar -xvf libtinfo.tar -C $fs
	cd tifs-8168
	tar -cvf ../ti.tar \
		usr/share/ti/ti-media-controller-utils \
		lib/modules \
		etc/init.d/load-hd* \
		usr/bin/prcm_config_app \
		usr/bin/firmware_loader \
		usr/sbin/fbset
	cd ../simplefs-8168
	tar -xvf ../ti.tar 
	sed -i '$aexport PATH=$PATH:/usr/sbin' etc/init.d/rcS 
	sed -i '$a/etc/init.d/load-hd-firmware.sh start' etc/init.d/rcS 
} || {
	cd emafs2
	tar -cvf ../ti.tar \
		usr/share/ti/ \
		lib/modules/ 
	cd ../simplefs-3530
	tar -xvf ../ti.tar 
	sed -i '$a. /usr/share/ti/gst/omap3530/loadmodules.sh' etc/init.d/rcS 
}
cd ..

tar -xvf $fs-root.tar

exit 0

