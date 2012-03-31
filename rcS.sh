
. /etc/host-profile.sh

telnetd -l /bin/sh
#. /usr/share/ti/gst/omap3530/loadmodules.sh

grep 37X /proc/cmdline && { 
	echo boot 3730
	cd /opt/3730
	#insmod cmemk.ko phys_start=0x86300000 phys_end=0x87300000 \
	#        pools=1x5250000,6x829440,1x345600,1x691200,1x1
	#insmod cmemk.ko phys_start=0x86300000 phys_end=0x87300000 \
	#        pools=1x5250000,6x829440,1x345600,1x691200,1x1
	insmod cmemk.ko phys_start=0x86300000 phys_end=0x87200000 pools=1x3000000,1x1429440,6x1048576,4x829440,1x327680,1x256000,7x131072,20x4096 allowOverlap=1
	#insmod cmemk.ko phys_start=0x86300000 phys_end=0x87200000 pools=1x3000000,1x1429440,6x1048576,3x1843200,1x327680,1x256000,7x131072,20x4096 allowOverlap=1
# 0x80000000     99 MB  Linux
# 0x86300000     15 MB  CMEM
# 0x87200000     13 MB  CODEC SERVER
	rm -f /dev/cmem
	mknod /dev/cmem c `awk '$2=="cmem" {print $1}' /proc/devices` 0
} 

grep 35X /proc/cmdline && {
	echo boot 3530
	cd /opt/3530/
	insmod cmemk.ko allowOverlap=1 phys_start=0x86300000 phys_end=0x87300000 \
	        pools=1x5250000,6x829440,1x345600,1x691200,1x1
}

# 0x80000000     99 MB  Linux
# 0x86300000     15 MB  CMEM
# 0x87200000     13 MB  CODEC SERVER
insmod dsplinkk.ko
rm -f /dev/dsplink
mknod /dev/dsplink c `awk '$2=="dsplink" {print $1}' /proc/devices` 0
insmod lpm_omap3530.ko
mknod /dev/lpm0 c `awk '$2~"lpm" {print $1}' /proc/devices` 0
insmod sdmak.ko
mknod /dev/video0 c 81 0

mkdir /dev/snd
cd /sys/class/sound
for i in control* pcm* mixer timer; do
	mknod /dev/snd/$i c `cat $i/dev | sed "s/:/ /"`
done

amixer set 'DAC1 Analog' off
amixer set 'DAC2 Analog' on
amixer set 'Codec Operation Mode' 'Option 1 (audio)'
#
amixer set 'Analog' 0
amixer set 'DAC Voice Analog Downlink' 0
amixer set TX1 'Analog'
amixer set 'TX1 Digital' 12
amixer set 'Analog Left AUXL' nocap
amixer set 'Analog Right AUXR' nocap
amixer set 'Analog Left Main Mic' cap
amixer set 'Analog Left Headset Mic' nocap

mkdir /hd
mount /dev/sda2 /hd

grep release_zc /proc/cmdline && {
	rm -rf /root/asys2/*
	myip=192.168.1.159
	ifconfig eth0 192.168.1.137 up
	ping $myip -w 1 -q > /dev/null && \
		mount -o nolock $myip:/home/zc/parents/Track /root/asys2
	cd /root/rec/
	./init.sh
}

grep nfs /proc/cmdline && {
	for i in $proj; do
		mount -o nolock $myip:$parentsdir/$i /root/$i
	done
}

ifconfig lo up
