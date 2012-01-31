
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

arm-2009q1: arm-2009q1-203-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
	tar -jxf $< 

dvsdk-3530: arm-2009q1 dvsdk_omap3530-evm_4_01_00_09_setuplinux
	@echo " ---- NOW Install dvsdk to ${PWD}/$@ ---- "
	@echo " ---- toolchain path ${PWD}/$</bin ---- "
	./dvsdk_omap3530-evm_4_01_00_09_setuplinux

simplefs:
	sudo ./mksimplefs.sh

remake-simplefs:
	sudo rm -rf simplefs
	sudo ./mksimplefs.sh
	make poweroff-all

ti-gst:
	make -C 


