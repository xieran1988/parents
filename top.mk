
ifneq (${plat}, pc)
crossprefix := ${toolchaindir}/bin/arm-none-linux-gnueabi-
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
LDFLAGS += $(shell perl ${parentsdir}/libcmd.pl ${sysrootdir} $(shell ${pkgvars} pkg-config ${libs} --libs 2> /dev/null))
LDFLAGS += ${sysrootdir}/usr/lib/libjpeg.so -pthread

define targetsh
ifeq (${plat}, pc)
$(1)
else
make open-and-telnet-${plat} cmd="$(1)"
endif
endef

world: all

kermitshell-3530:
	${parentsdir}/bootboard.pl kermrc3530 0 kermitshell

kermitshell-8168:
	${parentsdir}/bootboard.pl kermrc8168 2 kermitshell

ubootshell-3530:
	${parentsdir}/bootboard.pl kermrc3530 0 ubootshell

ubootshell-8168:
	${parentsdir}/bootboard.pl kermrc8168 2 ubootshell

emafs-3530:
	${parentsdir}/bootboard.pl kermrc3530 0 fs nand emafs args3530

simplefs-3530:
	${parentsdir}/bootboard.pl kermrc3530 0 fs nand simplefs-3530 args3530

simplefs-8168:
	${parentsdir}/bootboard.pl kermrc8168 2 fs uImage-dm816x-evm.bin simplefs-8168 args8168

tifs-8168:
	${parentsdir}/bootboard.pl kermrc8168 2 fs tifs-8168/boot/uImage-2.6.37 tifs-8168 args8168

mmcfs-8168:
	${parentsdir}/bootboard.pl kermrc8168 2 fs uImage-dm816x-evm.bin mmc args8168

telnet-3530:
	${parentsdir}/telnet.pl ${ip3530} "${cmd}"

telnet-8168:
	${parentsdir}/telnet.pl ${ip8168} "${cmd}"

enter-fs-and-exit-3530:
	${parentsdir}/bootboard.pl kermrc3530 0 enterfs nand simplefs-3530 args3530

enter-fs-and-exit-8168:
	${parentsdir}/bootboard.pl kermrc8168 2 enterfs uImage-dm816x-evm.bin simplefs-8168 args8168

open-and-telnet-3530: 
	make telnet-3530 cmd="${cmd}" || \
		( make enter-fs-and-exit-3530; make telnet-3530 cmd="${cmd}" )

open-and-telnet-8168: 
	make telnet-8168 cmd="${cmd}" || \
		( make enter-fs-and-exit-8168; make telnet-8168 cmd="${cmd}" )
	
poweroff-all:
	${parentsdir}/pwr.pl 1
	${parentsdir}/pwr.pl 3


