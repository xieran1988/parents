#!/bin/bash

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

sed "
/^GST_MAJORMINOR/s,=.*,=0.10,
/^GST_REQUIRED/s,=.*,=0.10.0,
/^GSTPB_REQUIRED/s,=.*,=0.10.0,
/^AS_VERSION(gstticode/s/GST_PLUGIN_VERSION,.*/GST_PLUGIN_VERSION, 0, 10, 0, 1,/
" -i gstreamer-ti*/configure.ac

sed "
11s/configure//
" -i gstreamer-ti*/Makefile.external

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

rm -rf gstreamer-ti_svnr884/src/*
ln -sv $parentsdir/gst-ti/* gstreamer-ti_svnr884/src/

ln -svf $parentsdir/dmai-3530/Capture.c dmai_2_20_00_14/packages/ti/sdo/dmai/linux/omap3530/

cp $parentsdir/dvsdk-3530-patch/Makefile .

make dsplink_arm && \
make dsplink_dsp && \
make dsplink_dsp_genpackage && \
make dsplink_gpp_genpackage && \
make c6accel && \
make codecs_clean && \
make codecs && \
make cmem && \
make sdma && \
make dmai

