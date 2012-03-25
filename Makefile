
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

make-bootsd-3730:
	sudo imgdir=emafs-3730 ./make-bootsd.pl

make-bootsd-3730-ti:
	sudo imgdir=tifs-3730/boot ./make-bootsd.pl

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

remake-tifs-3730:
	sudo rm -rf tifs-3730
	make tifs-3730

tifs-8168: dvsdk-8168
	mkdir $@
	sudo tar -xf dvsdk-8168/filesystem/ezsdk-dm816x-evm-rootfs.tar.gz -C $@
	sudo sed -i "/start-stop-daemon --start/s,$$, -- -l /bin/sh," $@/etc/init.d/telnetd
	sudo echo "Welcome to tifs-8168" > $@/etc/issue

tifs-3730: dvsdk-3730
	mkdir $@
	sudo tar -xf dvsdk-3730/filesystem/dvsdk-dm37x-evm-rootfs.tar.gz -C $@
	sudo ./mktifs.sh ${parentsdir}/$@

linux-ema-3730: linux-ema-3730.tar.bz2
	mkdir $@
	tar -xjf $< -C $@ --strip=1
	ln -sv arch/arm/boot/uImage $@/

make-linux-ema-3730: linux-ema-3730
	cd $< && \
	make ARCH=arm CROSS_COMPILE=${crossprefix} && \
	make ARCH=arm CROSS_COMPILE=${crossprefix} uImage

linux: 
	git clone git@github.com:xieran1988/linux.git

make-linux-shell: linux
	cd $< && \
	ARCH=arm CROSS_COMPILE=${crossprefix} bash
	make ARCH=arm CROSS_COMPILE=${crossprefix} uImage

simplefs:
	sudo ./mksimplefs.sh

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

gstreamer_ti:
	svn checkout --username anonymous https://gstreamer.ti.com/svn/gstreamer_ti/trunk/gstreamer_ti

try-tifs-3730:
	make remake-tifs-3730
	make boot-tifs-3730

try-simplefs-3730:
	make remake-simplefs
	make telnet-simplefs-3730

try-simplefs-3730-ema-kern:
	make remake-simplefs
	make telnet-simplefs-3730-ema-kern

try-simplefs-3530:
	make remake-simplefs
	make telnet-simplefs-3530

