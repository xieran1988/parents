
include top.mk

libav:
	git clone git@github.com:xieran1988/libav.git

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
	./build-dvsdk-3530.sh dvsdk-3530
	./reconf-gst-ti.sh

dvsdk-3730: dvsdk_dm3730-evm_04_03_00_06_setuplinux
	./dvsdk_dm3730-evm_04_03_00_06_setuplinux --forcehost --mode console --prefix ${parentsdir}/$@

remake-tifs-3730:
	sudo rm -rf tifs-3730
	make tifs-3730

tifs-3730: dvsdk-3730
	mkdir $@
	sudo tar -xf dvsdk-3730/filesystem/dvsdk-dm37x-evm-rootfs.tar.gz -C $@
	sudo ./mktifs.sh ${parentsdir}/$@

linux-ema-3730: linux-ema-3730.tar.bz2
	mkdir $@
	tar -xvjf $< -C $@
	mv $@/*/* $@
	ln -sv arch/arm/boot/uImage $@/

make-linux-ema-3730: linux-ema-3730
	cd $</* && \
	make ARCH=arm CROSS_COMPILE=${crossprefix}

simplefs:
	sudo ./mksimplefs.sh

remake-simplefs:
	sudo rm -rf simplefs
	mkdir simplefs
	sudo ./mksimplefs.sh
	make rebuild-gst-ti
	make poweroff-all

gstreamer_ti:
	svn checkout --username anonymous https://gstreamer.ti.com/svn/gstreamer_ti/trunk/gstreamer_ti

try-tifs-3730:
	 make remake-tifs-3730
	 make boot-tifs-3730

try-simplefs-3730:
	make remake-simplefs
	make simplefs-3730

