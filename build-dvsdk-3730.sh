#!/bin/bash

sdkdir=`realpath dvsdk-3730`
cp dvsdk-3530/linux-devkit/environment-setup dvsdk-3730/linux-devkit
cd dvsdk-3730
sed "/^CSTOOL_DIR/s,=.*,=$toolchaindir," -i Rules.make
sed "/^DVSDK_INSTALL_DIR/s,=.*,=$sdkdir," -i Rules.make
sed "s/arago/none/g" -i Makefile Rules.make
make dsplink_arm && \
make cmem && \
make sdma 

