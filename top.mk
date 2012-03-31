
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

sh:
	cd=/root/$(shell basename ${PWD}) make -C ${parentsdir} ${test}

login:
	$(call sh, /bin/sh)

pwddir := $(shell basename `pwd`)
dstdir := ${parentsdir}/simplefs/root/${pwddir}

cp-release-files:
	tar -cf - ${release_files} | tar -xf - -C $c


git-commit-and-push:
	git commit -a -m "`date`"
	git push
	
top:
	$(call sh, top -d1)

