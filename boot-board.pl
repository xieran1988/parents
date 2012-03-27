#!/usr/bin/env perl

use Expect;
use warnings;
use strict;

my %A;
my $board;
my $nfs;
my $kern;
my $burnmlo;
my $burnuboot;
my $burnkern;
my $burnubi;
my $loaduboot;
my $cmd;
my %sertbl = qw/8168 2 3730 1/;
my %pwrtbl = qw/8168 2 3730 0/;
my $e;

for my $a (@ARGV) {
	print "arg: $a\n";
	$board = $1 if $a =~ /-(3530|3730|8168)/;
	$nfs = $1 if $a =~ /-nfs=(.*)/;
	$kern = $1 if $a =~ /-kern=(.*)/;
	$burnmlo = $1 if $a =~ /-burnmlo=(.*)/;
	$burnuboot = $1 if $a =~ /-burnuboot=(.*)/;
	$burnkern = $1 if $a =~ /-burnkern=(.*)/;
	$burnubi = $1 if $a =~ /-burnubi=(.*)/;
	$loaduboot = $1 if $a =~ /-loaduboot=(.*)/;
	$cmd = $1 if $a =~ /-cmd=(.*)/;
	$A{$a}++;
}

my $myip = $ENV{'myip'};
my $gateip = "192.168.0.1";
my $net = "192.168.0.0";
my $armip = $ENV{"ip$board"};

sub end { 
	$e->interact(); exit;
}

retry_telnet:

if (exists $A{'-telnet'}) {
	$e = new Expect;
	$e->spawn("telnet $armip");
	if ($e->expect(2, '-re', "^Escape")) {
		$e->expect(2, '-re', "# ") or exit 123;
		$e->send("cd /root\n");
		$e->expect(2, '-re', "# ") or exit 123;
		if ($cmd) {
			$e->send("$cmd\n");
		}
		end;
	}
	exit if exists $A{'-noretry'};
}


my @arr = (
	"\x55\x01\x01\x02\x00\x00\x00\x59", # 1
	"\x55\x01\x01\x01\x00\x00\x00\x58",
	"\x55\x01\x01\x00\x02\x00\x00\x59", # 2
	"\x55\x01\x01\x00\x01\x00\x00\x58",
	"\x55\x01\x01\x00\x00\x02\x00\x59", # 3
	"\x55\x01\x01\x00\x00\x01\x00\x58",
	"\x55\x01\x01\x00\x00\x00\x02\x59", # 4
	"\x55\x01\x01\x00\x00\x00\x01\x58",
);
# speed 9600 baud; line = 0; -brkint -imaxbel
my $pwr = int($pwrtbl{$board});
`stty -F /dev/ttyUSB0 9600 -brkint -imaxbel line 0 echo`;
open T, ">/dev/ttyUSB0";
print T $arr[$pwr+1];
exit if exists $A{"-pwroff"};
print T $arr[$pwr];
close T;

$e = new Expect;
$e->spawn("kermit kermrc$sertbl{$board}");
$e->expect(10, '-re', "^--------") or die;
end if exists $A{'-kermit'};

sub uboot_exp {
	$e->expect(1000000, '-re', "^(OMAP3|TI8168)") or die;
}
sub uboot {
	my ($c) = @_; $e->send("$c\n"); uboot_exp;
}
sub waituboot {
	$e->expect(10, '-re', "^Hit") or die;
	$e->send("c");
	uboot_exp;
}
sub tftp {
	my ($u) = @_;
	uboot "setenv serverip $myip";
	uboot "setenv ipaddr $armip";
	uboot "setenv ethaddr 00:11:22:33:44:55" if $board ne '8168';
	`cp $u /var/lib/tftpboot/a`;
	uboot "tftp \${loadaddr} a";
}

waituboot;

if (exists $A{'-eraseall'}) {
	uboot "nandecc sw";
	uboot "nand erase";
}

if ($burnmlo) {
	uboot "nandecc hw";
	uboot "nand erase 0 80000";
	tftp $burnmlo;
	uboot "nand write.i \${loadaddr} 0 80000";
}

if ($burnuboot) {
	uboot "nandecc sw";
	uboot "nand erase 80000 160000";
	tftp $burnuboot;
	uboot "nand write.i \${loadaddr} 80000 160000"
}

if (exists $A{'-burnkernmmc'}) {
	uboot "mmc init";
	uboot "fatload mmc 0:1 80000000 uImage"; 
	uboot "nandecc sw";
	uboot "nand erase 280000 400000";
	uboot "nand write.i 80000000 280000 400000";
}

if ($burnkern) {
	uboot "nandecc sw";
	uboot "nand erase 280000 400000";
	tftp $burnkern;
	uboot "nand write.i \${loadaddr} 280000 400000";
}

if ($burnubi) {
	uboot "nandecc sw";
	uboot "nand erase 680000 8000000";
	tftp $burnubi;
	uboot "nand write.i \${loadaddr} 680000 \${filesize}";
}

my $bootargs;

if ($board eq '3530' or $board eq '3730') {
	my $mem = $board eq '3730' ? 
		"mem=99M\@0x80000000 mem=384M\@0x88000000" :
		"mem=99M\@0x80000000 mem=128M\@0x88000000 " ;
	my $tty = "ttyS0";
	my $model = $board eq '3730' ? 
		'SBC37X-A1-3990-LUAC0' : 'SBC35X-B1-1880-LUAC0';
	$bootargs = 
		"console=$tty,115200n8 " .
		"boardmodel=$model " .
		"vram=12M omapfb.mode=dvi:1024x768MR-16\@60 omapdss.def_disp=dvi " .
		"$mem " .
		"mpurate=1000 " .
		""
		;
}
if ($board eq '8168') {
	$bootargs = 
		"console=ttyO2,115200n8 rootwait rw mem=256M earlyprintk notifyk.vpssm3_sva=0xBF900000 vram=50M ti816xfb.vram=0:16M,1:16M,2:6M "
		;
}

if ($nfs) {
	$nfs = `realpath $nfs`;
	chomp $nfs;
	`./add-exportfs.sh $nfs`;
	$bootargs .= 
		"root=/dev/nfs nfsroot=$myip:$nfs " .
		"ip=$armip:$myip:$gateip:255.255.255.0:arm:eth0 ";
}
if (exists $A{'-nandboot'}) {
	$bootargs .= "root=ubi0:rootfs ubi.mtd=4 rootfstype=ubifs";
}

uboot "setenv nandargs setenv bootargs $bootargs";
uboot "saveenv";

exit if exists $A{'-exituboot'};
end if exists $A{'-uboot'};

if ($loaduboot) {
	tftp $loaduboot;
	$e->send("go \${loadaddr}\n");
	waituboot;
}

if ($kern) {
	tftp $kern;
} else {
	uboot "nand read \${loadaddr} 280000 400000";
}
$e->send("run nandargs; bootm \${loadaddr}\n");

if (exists $A{'-telnet'}) {
	$e->expect(1000000, "-re", "^Welcome");
	goto retry_telnet;
}

end;

