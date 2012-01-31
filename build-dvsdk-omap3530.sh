#!/bin/bash

# Change to your dvsdk path
sdkdir=$parentsdir/dvsdk-3530
cd $sdkdir

sed "/^clean:/{s, demos_clean, ,;s,linux_clean,,}" -i Makefile

sed "/^CSTOOL_DIR/s,=.*,=$toolchaindir," -i Rules.make
sed "/^DVSDK_INSTALL_DIR/s,=.*,=$sdkdir," -i Rules.make
sed "
/^export TOOLCHAIN_PATH/s,=.*,=$toolchaindir,
/^export SDK_PATH/s,=.*,=$sysrootdir,
/^export CPATH/s,\$TARGET_SYS,,
/^export LIBTOOL_SYSROOT_PATH/s,\$TARGET_SYS,,
/^export PKG_CONFIG_SYSROOT_DIR/s,\$TARGET_SYS,,
/^export PKG_CONFIG_PATH/s,\$TARGET_SYS,,
" -i linux-devkit/environment-setup

# Change to your gstreamer plugin version in buildroot
sed "
/^GST_MAJORMINOR/s,=.*,=0.10,
/^GST_REQUIRED/s,=.*,=0.10.0,
/^GSTPB_REQUIRED/s,=.*,=0.10.0,
/^AS_VERSION(gstticode/s/GST_PLUGIN_VERSION,.*/GST_PLUGIN_VERSION, 0, 10, 0, 1,/
" -i gstreamer-ti*/configure.ac

sed "
150s,physPtr.*,physPtr=0;,
" -i dmai_2_20_00_14/packages/ti/sdo/dmai/linux/omap3530/Display_fbdev.c

sed "
/^#define restrict$/{
s,$,//modified,
i#undef restrict
}
" -i xdctools_3_16_03_36/packages/xdc/std.h

sed "
/^CPP_FLAGS +=.*[^C]$/s,$, -fPIC,
" -i c6accel_1_01_00_02/soc/c6accelw/Makefile

sed "
/^libgstticodecplugin_la_LIBADD/s,=.*,=,
" -i gstreamer-ti_svnr884/src/Makefile.am

make linux && \
make cmem && \
make dsplink && \
make c6accel && \
make codecs && \
make dmai && \
make gstreamer_ti

make linux && \
make cmem && \
make dsplink && \
make c6accel && \
make codecs && \
make dmai && \
make gstreamer_ti

