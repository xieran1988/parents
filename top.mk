
ifeq (${plat}, a8)
pkgvars += PKG_CONFIG_SYSROOT_DIR="${sysrootdir}" 
pkgvars += PKG_CONFIG_PATH="${sysrootdir}/usr/lib/pkgconfig/"
CFLAGS += -O3 -P 
CFLAGS += -mfloat-abi=softfp 
CFLAGS += -mfpu=neon -ftree-vectorize 
CFLAGS += -mcpu=cortex-a8 -mtune=cortex-a8 -Wall 
endif

ifeq (${plat}, pc)
sysrootdir := /
endif

CC := ${crossprefix}gcc
OBJDUMP := ${crossprefix}objdump

CFLAGS += $(shell ${pkgvars} pkg-config ${libs} --cflags 2> /dev/null)
CFLAGS += -I${sysrootdir}/usr/lib/glib-2.0/include -I${sysrootdir}/usr/include
CFLAGS += -fPIC
CFLAGS += -I.

LDFLAGS += $(shell ${parentsdir}/pkg-config.pl \
					 ${sysrootdir} -ljpeg \
					 $(shell ${pkgvars} pkg-config ${libs} --libs 2> /dev/null))
#LDFLAGS += ${sysrootdir}/lib/libpthread.so.0
#LDFLAGS += ${sysrootdir}/lib/libc.so.6
LDFLAGS += -pthread
LDFLAGS += --sysroot=${sysrootdir}

ifeq (${plat}, pc)
define sh
$(1)
endef
else
define sh
${parentsdir}/add-exportfs.sh ${PWD}
make ${test} c=". /mount-and-docmd.sh ${myip} ${PWD} $1" -C ${parentsdir}
endef
endif

define linkit
	${CC} -o $$@ $$< ${LDFLAGS}
endef

define single-target
$1: $1.o
	${CC} -o $$@ $$< ${LDFLAGS}
$1-test: $1 
	$$(call sh,./$1)
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
	$$(call sh,gst-inspect $2)
endef

world: all

login:
	$(call sh, /bin/sh)

release: 
	cd ${parentsdir} && make remake-simplefs
	sudo cp -Rv ${release_objs} ${parentsdir}/simplefs/root
	cd ${parentsdir} && make make-ubifs-simplefs

make-ubifs-simplefs: simplefs
	sudo mkfs.ubifs -r simplefs -m 2048 -e 129024 -c 1998 -o ubifs.img 
	sudo ubinize -o ubi.img -m 2048 -p 128KiB -s 512 ubinize.cfg

boot := ${parentsdir}/boot-board.pl

boot-kermit-3530:
	${boot} -3530 -kermit

boot-kermit-8168:
	${boot} -8168 -kermit

boot-uboot-3530:
	${boot} -3530 -uboot

boot-uboot-3730:
	${boot} -3730 -uboot

boot-uboot-8168:
	${boot} -8168 -uboot

boot-emafs-3530: emafs-3530
	${boot} -3530 -nfs=$< 

boot-emafs-3730: emafs-3730
	${boot} -3730 -nfs=$<

boot-burnkernmmc-3730:
	${boot} -3730 -burnkernmmc -exituboot

boot-burnall-3730:
	${boot} -3730 \
		-eraseall \
		-burnmlo=emafs-3730/MLO \
		-burnuboot=emafs-3730/u-boot.bin \
		-burnkern=emafs-3730/uImage \
		-burnubi=ubi.img \
		-nandboot \
		-ubootdelay0 \
		-exituboot

telnet-3730:
	${boot} -3730 -telnet -cmd="$c" -noretry

telnet-simplefs-3530: simplefs
	${boot} -3530 -nfs=$< -telnet -cmd="$c"

telnet-simplefs-3730: simplefs
	${boot} -3730 -nfs=$< -telnet -cmd="$c"

telnet-tifs-8168:
	${boot} -8168 -nfs=$< -telnet -cmd="$c"

telnet-simplefs-3730-ema-kern: simplefs
	${boot} -3730 -nfs=$< -kern=linux-ema-3730/uImage -telnet -cmd="$c"

boot-tifs-8168: tifs-8168
	${boot} -8168 -nfs=$< -kern=$</boot/uImage-2.6.37

boot-tifs-3730-ti-kern: tifs-3730
	${boot} -3730 -nfs=$< -kern=$</boot/uImage 

boot-tifs-3730-ema-kern: tifs-3730 emafs-3730
	${boot} -3730 -nfs=$< -kern=emafs-3730/boot/uImage 

poweroff-all:
	${boot} -3530 -pwroff
	${boot} -3730 -pwroff
	${boot} -8168 -pwroff

rebuild-gst-ti: rebuild-dmai
	${parentsdir}/$@.sh > /dev/null

rebuild-rtsp:
	${parentsdir}/$@.sh > /dev/null

rebuild-dmai:
	${parentsdir}/$@.sh > /dev/null

rebuild-gst-alsasrc:
	${parentsdir}/$@.sh > /dev/null

rebuild-mod-auth-ticket: ${parentsdir}/mod-auth-ticket-for-lighttpd
	make -C $<
	sudo cp -v $</*.so simplefs/usr/lib/lighttpd

git-commit-and-push:
	git commit -a -m "`date`"
	git push
	
top:
	$(call sh, top -d1)

