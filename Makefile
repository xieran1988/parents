
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


