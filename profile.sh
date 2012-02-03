export buildrootdir=$parentsdir/buildroot
export toolchaindir=$buildrootdir/output/host/opt/ext-toolchain
export crossprefix=$toolchaindir/bin/arm-none-linux-gnueabi-
export sysrootdir=$buildrootdir/output/host/usr/arm-unknown-linux-gnueabi/sysroot/
export PATH=$PATH:$toolchaindir/bin
export builddir=$buildrootdir/output/build
export gstbuilddir=$buildrootdir/output/build/gstreamer-0.10.35
export tigstbuilddir=$parentsdir/dvsdk-3530/gstreamer-ti_svnr884/src
export dvsdkdir=$parentsdir/dvsdk-3530
export myip=192.168.1.174
export ip3530=192.168.1.36
export ip8168=192.168.1.37
