#!/usr/bin/perl

my $d;
open F, "find /sys/class/block/ | ";
while (<F>) {
	chomp;
	if (-e "$_/device" && `realpath $_/device` =~ /usb/ && `cat $_/device/model` =~ /Multi-Reader/) {
		$d = `basename $_`;
		my $r = system("./mkcard.sh /dev/$d") >> 8;
		exit if ($r == 0);
	}
}
print "ERROR: make sure sdcard is 2G\n";

exit 1;

