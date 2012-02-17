
include top.mk

buildroot:
	git clone git://git.buildroot.net/buildroot
	
emafs: sbc_ncast_fs20111123.7z
	7z x sbc_ncast_fs20111123.7z
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

arm-2009q1: arm-2009q1-203-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
	tar -jxf $< 

dvsdk-3530: arm-2009q1 dvsdk_omap3530-evm_4_01_00_09_setuplinux gstreamer_ti
	@echo " -------------------------------------------"
	@echo " -------------------------------------------"
	@echo " ---- PLEASE Install dvsdk to ${PWD}/$@ ---- "
	@echo " ---- toolchain path ${PWD}/$</bin ---- "
	@echo " -------------------------------------------"
	@echo " -------------------------------------------"
	./dvsdk_omap3530-evm_4_01_00_09_setuplinux --forcehost --mode console --prefix ${parentsdir}/$@
	cp -R gstreamer_ti/ti_build/ticodecplugin/src/* dvsdk-3530/gstreamer-ti*/src
	./build-dvsdk-3530.sh dvsdk-3530
	./reconf-gst-ti.sh

simplefs:
	sudo ./mksimplefs.sh

remake-simplefs:
	sudo rm -rf simplefs
	sudo ./mksimplefs.sh
	make rebuild-gst-ti
	make poweroff-all

gstreamer_ti:
	svn checkout --username anonymous https://gstreamer.ti.com/svn/gstreamer_ti/trunk/gstreamer_ti

