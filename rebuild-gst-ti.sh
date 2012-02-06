#!/bin/bash

cd $parentsdir/dvsdk-3530 && \
make gstreamer_ti && \
cd gstreamer*/src && \
arm-none-linux-gnueabi-gcc -shared  -fPIC -DPIC \
	$sysrootdir/usr/lib/libgstreamer-0.10.so \
	$sysrootdir/usr/lib/libgstbase-0.10.so \
	$sysrootdir/usr/lib/libgstvideo-0.10.so \
	.libs/libgstticodecplugin_la-gsttiauddec1.o \
	.libs/libgstticodecplugin_la-gsttiaudenc1.o \
	.libs/libgstticodecplugin_la-gsttic6xcolorspace.o \
	.libs/libgstticodecplugin_la-gstticapturesrc.o \
	.libs/libgstticodecplugin_la-gstticircbuffer.o \
	.libs/libgstticodecplugin_la-gstticodecplugin.o \
	.libs/libgstticodecplugin_la-gstticodecs.o \
	.libs/libgstticodecplugin_la-gstticodecs_platform.o \
	.libs/libgstticodecplugin_la-gstticommonutils.o \
	.libs/libgstticodecplugin_la-gsttidmaibuffertransport.o \
	.libs/libgstticodecplugin_la-gsttidmaibuftab.o \
	.libs/libgstticodecplugin_la-gsttidmaiperf.o \
	.libs/libgstticodecplugin_la-gsttidmaivideosink.o \
	.libs/libgstticodecplugin_la-gsttiimgdec1.o \
	.libs/libgstticodecplugin_la-gsttiimgenc1.o \
	.libs/libgstticodecplugin_la-gsttiprepencbuf.o \
	.libs/libgstticodecplugin_la-gsttiquicktime_aac.o \
	.libs/libgstticodecplugin_la-gsttiquicktime_h264.o \
	.libs/libgstticodecplugin_la-gsttiquicktime_mpeg4.o \
	.libs/libgstticodecplugin_la-gsttividdec2.o \
	.libs/libgstticodecplugin_la-gsttividenc1.o \
	.libs/libgstticodecplugin_la-gsttividresize.o \
	-pthread -march=armv5t -O2 -Wl,gstticodecplugin_omap3530/linker.cmd \
	-Wl,$parentsdir/dvsdk-3530/c6accel_1_01_00_02/soc/c6accelw/lib/c6accelw_omap3530.a470MV \
 	-pthread -Wl,-soname -Wl,libgstticodecplugin.so -Wl,-version-script -Wl,.libs/libgstticodecplugin.ver \
	-o .libs/libgstticodecplugin.so && \
sudo cp -v .libs/libgstticodecplugin.so $parentsdir/simplefs/usr/lib/gstreamer-0.10 && \
cd $builddir/gst-plugins-base-0.10.35/ext/alsa && \
make && \
sudo cp -v .libs/libgstalsa.so $parentsdir/simplefs/usr/lib/gstreamer-0.10/libgstalsa.so 
