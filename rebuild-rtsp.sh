#!/bin/sh

cd $builddir/gst-rtsp-*/gst/rtsp-server && \
make && \
sudo cp -v .libs/*.so $parentsdir/simplefs/usr/lib

