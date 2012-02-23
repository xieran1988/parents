
ifneq (${plat}, pc)
pkgvars += PKG_CONFIG_SYSROOT_DIR="${sysrootdir}" 
pkgvars += PKG_CONFIG_PATH="${sysrootdir}/usr/lib/pkgconfig/"
CFLAGS += -O3 -P 
CFLAGS += -mfloat-abi=softfp 
CFLAGS += -mfpu=neon -ftree-vectorize 
CFLAGS += -mcpu=cortex-a8 -mtune=cortex-a8 -Wall 
else
sysrootdir := /
endif
CC := ${crossprefix}gcc
OBJDUMP := ${crossprefix}objdump
CFLAGS += $(shell ${pkgvars} pkg-config ${libs} --cflags 2> /dev/null)
CFLAGS += -I${sysrootdir}/usr/lib/glib-2.0/include -I${sysrootdir}/usr/include
CFLAGS += -fPIC
LDFLAGS += $(shell ${parentsdir}/pkg-config.pl \
					 ${sysrootdir} -ljpeg \
					 $(shell ${pkgvars} pkg-config ${libs} --libs 2> /dev/null))
LDFLAGS += -pthread

ifeq (${plat}, pc)
define sh
$(1)
endef
else
define sh
${parentsdir}/add-exportfs.sh ${PWD}
make ${test} c="/mount-and-docmd.sh ${myip} ${PWD} $1" -C ${parentsdir}
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

boot := ${parentsdir}/boot-board.pl

boot-kermit-3530:
	${boot} -3530 -kermit

boot-kermit-8168:
	${boot} -8168 -kermit

boot-uboot-3530:
	${boot} -3530 -uboot

boot-uboot-8168:
	${boot} -8168 -uboot

boot-emafs-3530: emafs-3530
	${boot} -3530 -nfs=$< 

boot-emafs-3730: emafs-3730
	${boot} -3730 -nfs=$<

boot-burnkern-3730:
	${boot} -3730 -burnkern

telnet-simplefs-3530: simplefs
	${boot} -3530 -nfs=$< -telnet -cmd="$c"

telnet-simplefs-3730: simplefs
	${boot} -3730 -nfs=$< -telnet -cmd="$c"

telnet-simplefs-3730-ema-kern: simplefs
	${boot} -3730 -nfs=$< -kern=linux-ema-3730/uImage -telnet -cmd="$c"

boot-tifs-3730-ti-kern: tifs-3730
	${boot} -3730 -nfs=$< -kern=$</boot/uImage 

boot-tifs-3730-ema-kern: tifs-3730 emafs-3730
	${boot} -3730 -nfs=$< -kern=emafs-3730/boot/uImage 

poweroff-all:
	${boot} -3530 -pwroff
	${boot} -3730 -pwroff

rebuild-gst-ti: rebuild-dmai
	${parentsdir}/$@.sh > /dev/null

rebuild-rtsp:
	${parentsdir}/$@.sh > /dev/null

rebuild-dmai:
	${parentsdir}/$@.sh > /dev/null

rebuild-gst-alsasrc:
	${parentsdir}/$@.sh > /dev/null

git-commit-and-push:
	git commit -a -m "`date`"
	git push
	
top:
	$(call sh, top -d1)

