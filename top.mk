
ifneq (${plat}, pc)
pkgvars := PKG_CONFIG_SYSROOT_DIR="${sysrootdir}" PKG_CONFIG_PATH="${sysrootdir}/usr/lib/pkgconfig/"
CFLAGS += \
	-O3 -P \
	-mfloat-abi=softfp -mfpu=neon -ftree-vectorize \
	-mcpu=cortex-a8 -mtune=cortex-a8 -Wall 
else
sysrootdir := /
endif
CC := ${crossprefix}gcc
OBJDUMP := ${crossprefix}objdump
CFLAGS += $(shell ${pkgvars} pkg-config ${libs} --cflags 2> /dev/null)
CFLAGS += -I${sysrootdir}/usr/lib/glib-2.0/include -I${sysrootdir}/usr/include
CFLAGS += -fPIC
LDFLAGS += $(shell ${parentsdir}/libcmd.pl ${sysrootdir} -ljpeg $(shell ${pkgvars} pkg-config ${libs} --libs 2> /dev/null))
LDFLAGS += -pthread

LDFLAGS_TIGST += -Wl,${tigstbuilddir}/src/gstticodecplugin_omap3530/linker.cmd 
LDFLAGS_TIGST += -Wl,${dvsdkdir}/c6accel_1_01_00_02/soc/c6accelw/lib/c6accelw_omap3530.a470MV
CFLAGS_TIGST += -I${dvsdkdir}/dvsdk-3530/xdctools_3_16_03_36/packages 
CFLAGS_TIGST += -I${dvsdkdir}/dsplink_1_65_00_02 
CFLAGS_TIGST += -I${dvsdkdir}/framework-components_2_25_03_07/packages 
CFLAGS_TIGST += -I${dvsdkdir}/codec-engine_2_26_01_09/packages 
CFLAGS_TIGST += -I${dvsdkdir}/xdais_6_26_00_02/packages 
CFLAGS_TIGST += -I${dvsdkdir}/codecs-omap3530_4_00_00_00/packages 
CFLAGS_TIGST += -I${dvsdkdir}/linuxutils_2_25_05_11/packages 
CFLAGS_TIGST += -I${dvsdkdir}/dmai_2_20_00_14/packages 
CFLAGS_TIGST += -I${dvsdkdir}/local-power-manager_1_24_02_09/packages 
CFLAGS_TIGST += -I${dvsdkdir}/edma3lld_01_11_00_03/packages 
CFLAGS_TIGST += -I${dvsdkdir}/c6accel_1_01_00_02/soc/c6accelw 
CFLAGS_TIGST += -I${dvsdkdir}/c6accel_1_01_00_02/soc/packages 
CFLAGS_TIGST += -I${dvsdkdir}/xdctools_3_16_03_36/packages 
CFLAGS_TIGST += -I${dvsdkdir}/gstreamer-ti_svnr884/src/gstticodecplugin_omap3530/.. 
CFLAGS_TIGST += -Dxdc_target_types__=gnu/targets/arm/std.h 
CFLAGS_TIGST += -Dxdc_target_name__=GCArmv5T 
CFLAGS_TIGST += -Dxdc_cfg__header__=${tigstbuilddir}/src/gstticodecplugin_omap3530/package/cfg/gstticodecplugin_omap3530_xv5T.h

ifeq (${plat}, pc)
define targetsh
$(1)
endef
else
define targetsh
${parentsdir}/add-exportfs.sh ${PWD}
make open-and-telnet-${plat} cmd="/mount-and-docmd.sh ${myip} ${PWD} $1"
endef
endif

define linkit
	${CC} -o $$@ $$< ${LDFLAGS}
endef

define single-target
$1: $1.o
	${CC} -o $$@ $$< ${LDFLAGS}
$1-test: $1 
	$$(call targetsh,./$1)
endef

fdsrc_src := ${parentsdir}/gstfdsrc
fdsrc_pat := fd
fdsrc_list := {p}_src {p}src {U}_SRC {u}Src

valve_src := ${parentsdir}/gstvalve
valve_pat := valve
valve_list := {p} {U} {u}

define my-gst-plugin
$2.c $2.h:
	${parentsdir}/gen-my-gst-plugin.pl ${$1_src} ${$1_pat} $2 ${$1_list}
$2.o: $2.h
$2.so: $2.o
	${CC} -shared -o $$@ $$< ${LDFLAGS}
inspect-$2: $2.so
	$$(call targetsh,gst-inspect $2)
endef

world: all

kermitshell-3530:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc3530 0 kermitshell

kermitshell-8168:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc8168 2 kermitshell

ubootshell-3530:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc3530 0 ubootshell

ubootshell-8168:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc8168 2 ubootshell

emafs-3530:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc3530 0 fs nand ${parentsdir}/emafs args3530

simplefs-3530:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc3530 0 fs nand ${parentsdir}/simplefs args3530

simplefs-8168:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc8168 2 fs uImage-dm816x-evm.bin simplefs args8168

tifs-8168:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc8168 2 fs tifs-8168/boot/uImage-2.6.37 tifs-8168 args8168

mmcfs-8168:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc8168 2 fs uImage-dm816x-evm.bin mmc args8168

ssh-3530:
	ssh root@${ip3530}

telnet-3530:
	${parentsdir}/telnet.pl ${ip3530} "${cmd}"

telnet-8168:
	${parentsdir}/telnet.pl ${ip8168} "${cmd}"

enter-fs-and-exit-3530:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc3530 0 enterfs nand ${parentsdir}/simplefs args3530

enter-fs-and-exit-8168:
	${parentsdir}/bootboard.pl ${parentsdir}/kermrc8168 2 enterfs uImage-dm816x-evm.bin simplefs args8168

open-and-telnet-3530: 
	make telnet-3530 cmd="${cmd}" || \
		( make enter-fs-and-exit-3530; make telnet-3530 cmd="${cmd}" )

open-and-telnet-8168: 
	make telnet-8168 cmd="${cmd}" || \
		( make enter-fs-and-exit-8168; make telnet-8168 cmd="${cmd}" )
	
poweroff-all:
	${parentsdir}/pwr.pl 1
	${parentsdir}/pwr.pl 3

rebuild-gst-ti: rebuild-dmai
	${parentsdir}/$@.sh

rebuild-rtsp:
	${parentsdir}/rebuild-rtsp.sh

rebuild-dmai:
	${parentsdir}/rebuild-dmai.sh

git-commit-and-push:
	git commit -a -m "`date`"
	git push
	
top-3530:
	make open-and-telnet-3530 cmd="top -d1"



