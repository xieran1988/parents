
include top.mk

libav:
	git clone git@github.com:xieran1988/libav.git

mod-auth-ticket-for-lighttpd:
	git clone git@github.com:xieran1988/mod-auth-ticket-for-lighttpd.git

buildroot:
	git clone git@github.com:xieran1988/buildroot.git
#	git clone git://git.buildroot.net/buildroot
	
emafs: ema-3530-fs.7z
	7z x $<.7z
	mkdir $@
	sudo tar -jxf sbc_ncast_fs20111123/sbc_ncast_fs1123.tar.bz2 -C $@ 
	sudo mv sbc_ncast_fs20111123/MLO $@
	sudo mv sbc_ncast_fs20111123/uImage $@
	sudo mv sbc_ncast_fs20111123/u-boot.bin $@
	rm -rf sbc_ncast_fs20111123

emafs-3730: ema-3730-boot.tar ema-3730-fs.tar.bz2
	mkdir $@
	sudo tar -xf ema-3730-boot.tar -C $@
	sudo tar -xjf ema-3730-fs.tar.bz2 -C $@

arm-2009q1: arm-2009q1-203-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
	tar -jxf $< 

dvsdk-3530: arm-2009q1 dvsdk_omap3530-evm_4_01_00_09_setuplinux
	@echo " -------------------------------------------"
	@echo " ---- toolchain path ${PWD}/$</bin ---- "
	@echo " -------------------------------------------"
	./dvsdk_omap3530-evm_4_01_00_09_setuplinux --forcehost --mode console --prefix ${parentsdir}/$@
	./build-dvsdk-3530.sh
	./reconf-gst-ti.sh

dvsdk-3730: dvsdk_dm3730-evm_04_03_00_06_setuplinux dvsdk-3530 linux-ema-3730
	./dvsdk_dm3730-evm_04_03_00_06_setuplinux --forcehost --mode console --prefix ${parentsdir}/$@
	./build-dvsdk-3730.sh

dvsdk-8168: arm-2009q1 ezsdk_dm816x-evm_5_03_00_09_setuplinux
	@echo " -------------------------------------------"
	@echo " ---- toolchain path ${PWD}/$</bin ---- "
	@echo " -------------------------------------------"
	./ezsdk_dm816x-evm_5_03_00_09_setuplinux --forcehost --mode console --prefix ${parentsdir}/$@

linux: 
	git clone git@github.com:xieran1988/linux.git

tifs-8168: dvsdk-8168
	mkdir $@
	sudo tar -xf dvsdk-8168/filesystem/ezsdk-dm816x-evm-rootfs.tar.gz -C $@
	sudo sed -i "/start-stop-daemon --start/s,$$, -- -l /bin/sh," $@/etc/init.d/telnetd
	sudo echo "Welcome to tifs-8168" > $@/etc/issue

tifs-3730: dvsdk-3730
	mkdir $@
	sudo tar -xf dvsdk-3730/filesystem/dvsdk-dm37x-evm-rootfs.tar.gz -C $@
	sudo ./mktifs.sh ${parentsdir}/$@

gstreamer_ti:
	svn checkout --username anonymous https://gstreamer.ti.com/svn/gstreamer_ti/trunk/gstreamer_ti

gstreamer_ti_dm81xx: gst-ti-81xx-svn.tar.bz2
	tar -xf $<

linux-ema-3730: linux-ema-3730.tar.bz2
	mkdir $@
	tar -xjf $< -C $@ --strip=1
	ln -sv arch/arm/boot/uImage $@/

make-linux-ema-3730: linux-ema-3730
	cd $< && \
	make ARCH=arm CROSS_COMPILE=${crossprefix} && \
	make ARCH=arm CROSS_COMPILE=${crossprefix} uImage

make-bootsd-3730:
	sudo imgdir=emafs-3730 ./make-bootsd.pl

make-bootsd-3730-ti:
	sudo imgdir=tifs-3730/boot ./make-bootsd.pl

make-linux-shell: 
	cd $< && \
	ARCH=arm CROSS_COMPILE=${crossprefix} bash
	make ARCH=arm CROSS_COMPILE=${crossprefix} uImage

remake-simplefs:
	sudo rm -rf simplefs
	mkdir simplefs
	sudo ./mksimplefs.sh
	make rebuild-gst-ti
	make rebuild-mod-auth-ticket
	make poweroff-all

remake-gst-ffmpeg:
	cd buildroot && make ffmpeg-reconfigure && make gst-ffmpeg-reconfigure
	make remake-simplefs

remake-tifs-3730:
	sudo rm -rf tifs-3730
	make tifs-3730

prepare-81xx:
	cd dvsdk-8168/linux-devkit/arm-none-linux-gnueabi/usr/lib/
	mkdir .libs
	cp libz.* .libs
	cd -
	cd gstreamer_ti_dm81xx

try-tifs-3730:
	make remake-tifs-3730 boot-tifs-3730

try-simplefs-3730:
	make remake-simplefs
	make telnet-simplefs-3730

try-simplefs-3730-ema-kern:
	make remake-simplefs
	make telnet-simplefs-3730-ema-kern

try-simplefs-3530:
	make remake-simplefs
	make telnet-simplefs-3530

release: 
	make remake-simplefs
	make make-ubifs-simplefs

build-dep:
	sudo ln -sv `pwd`/arm-2009q1 /usr/local/arm/
	sudo apt-get install u-boot-tools uboot-mkimage

make-ubifs-simplefs: simplefs
	sudo mkfs.ubifs -r simplefs -m 2048 -e 129024 -c 1998 -o ubifs.img 
	sudo ubinize -o ubi.img -m 2048 -p 128KiB -s 512 ubinize.cfg

boot := ${parentsdir}/boot-board.pl

boot-kermit-3730:
	board=3730 mode=kermit ${boot}

boot-kermit-8168:
	board=8168 mode=kermit ${boot}

boot-nandboot-3730:
	board=3730 defenv=1 ${boot}

boot-uboot-3530:
	board=3530 mode=uboot ${boot} 

boot-uboot-3730:
	board=3730 mode=uboot ${boot} 

boot-uboot-8168:
	board=8168 mode=uboot ${boot} 

boot-emafs-3530: emafs-3530
	board=3530 mode=nfs nfs=$< ${boot} 

boot-emafs-3730: emafs-3730
	board=3730 mode=nfs nfs=$< ${boot}

boot-tifs-8168: tifs-8168
	board=8168 mode=nfs nfs=$< kern=$</boot/uImage-2.6.37 ${boot}

boot-tifs-3730-ti-kern: tifs-3730
	board=3730 mode=nfs nfs=$< kern=$</boot/uImage ${boot}

boot-tifs-3730-ema-kern: tifs-3730 emafs-3730
	board=3730 mode=nfs nfs=$< kern=emafs-3730/boot/uImage ${boot}

boot-simplefs-3730: simplefs 
	board=3730 mode=nfs nfs=$< ${boot}

boot-burn-3730:
	board=3730 mode=burn ${boot}

boot-burnkernmmc-3730:
	board=3730 mode=burn burn=kernmmc ${boot}

boot-burnall-3730: emafs-3730
	board=3730 mode=burn saveenv=1 nandboot=1 \
	burn=erase,mlo,uboot,kern,ubi \
	mlo=$</MLO uboot=$</u-boot.bin kern=$</uImage ubi=ubi.img \
	${boot}

release-test:
	bootparm=release_zc make release boot-burnall-3730 boot-kermit-3730

telnet-3530: 
	cd=/root ip=${ip3530} ./telnet.pl 

telnet-3730: 
	cd=/root ip=${ip3730} ./telnet.pl 

telnet-8168: 
	ip=${ip8168} ./telnet.pl 
	
poweroff-all:
	board=3570 pwroff=1 ${boot} 
	board=8168 pwroff=1 ${boot} 

rebuild-gst-ti: rebuild-dmai
	./$@.sh > /dev/null

rebuild-rtsp: 
	( cd ${builddir}/gst-rtsp-*/gst/rtsp-server && \
	make && \
	sudo cp .libs/*.so ${parentsdir}/simplefs/usr/lib ) > /dev/null

rebuild-dmai: 
	( cd dvsdk-3530 && \
	make dmai ) > /dev/null

rebuild-gst-alsasrc:
	( cd ${builddir}/gst-plugins-base-0.10.35/ext/alsa && \
	sudo cp .libs/libgstalsa.so ${parentsdir}/simplefs/usr/lib/gstreamer-0.10/libgstalsa.so ) > /dev/null

rebuild-mod-auth-ticket: mod-auth-ticket-for-lighttpd
	make -C $<
	sudo cp $</*.so simplefs/usr/lib/lighttpd

