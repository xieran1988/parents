
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
CFLAGS += -fPIC
LDFLAGS += $(shell ${parentsdir}/libcmd.pl ${sysrootdir} -ljpeg $(shell ${pkgvars} pkg-config ${libs} --libs 2> /dev/null))
LDFLAGS += -pthread

ifeq (${plat}, pc)
define targetsh
$(1)
endef
else
define targetsh
${parentsdir}/add-exportfs.sh ${PWD}
make open-and-telnet-${plat} cmd="/mount-and-docmd.sh ${myip} ${PWD} $1 #expect-interact"
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
fdsrc_list := !psrc !p_src !U_SRC !uSrc

define my-gst-plugin
.PHONY: $2.c $2.h
$2.c $2.h:
	${parentsdir}/make-my-gst-plugin.pl ${$1_src} ${$1_pat} $2 ${$1_list}
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


