#!/bin/bash

cd $builddir/gst-plugins-base-0.10.35/ext/alsa && \
sudo cp .libs/libgstalsa.so $parentsdir/simplefs/usr/lib/gstreamer-0.10/libgstalsa.so 
