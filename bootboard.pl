#!/usr/bin/env perl

use Expect;
use warnings;
use strict;

my $e;

my $kermrc = $ARGV[0];
my $pwron = int($ARGV[1]);
my $cmd = $ARGV[2];
my $uimage = $ARGV[3];
my $fs = $ARGV[4] if $ARGV[4];
my $fspath;
my $args = $ARGV[5] if $ARGV[5];

sub uboot_exp { 
	$e->expect(1000000, '-re', "^(OMAP3|TI8168)") or die;
}

sub uboot {
	my ($c) = @_;
	$e->send("$c\n");
	uboot_exp;
}

$e = new Expect;
$e->spawn("kermit $kermrc");

my $parentsdir = $ENV{'parentsdir'};

print "power reset ..\n";
my $pwroff = $pwron + 1;
`$parentsdir/pwr.pl $pwroff`;
`$parentsdir/pwr.pl $pwron`;

$e->expect(10, '-re', "^--------") or die;

if ($cmd eq 'kermitshell') {
	$e->interact();
}

$e->expect(10, '-re', "^Hit") or die;
$e->send("c");
uboot_exp;

if ($cmd eq 'ubootshell') {
	$e->interact();
}

print "fs: $fs\n";

if ($fs ne 'mmc' && $fs ne 'none') {
	$fspath = `realpath $fs` if $fs;
	chomp $fspath if $fspath;
	die "fspath $fspath should not be empty !!" if !$fspath;
	`$parentsdir/add-exportfs.sh $fspath`;
}

my $myip = $ENV{'myip'};
my $gateip = "192.168.1.1";
my $net = "192.168.1.0";
my $armip;

if ($args eq 'args3530') {
	$armip = $ENV{'ip3530'};
	my $cfg = "
auto eth0
	iface eth0 inet static
	address $armip
	netmask 255.255.255.0
	network $net
#gateway $gateip
";
#	`sudo echo "$cfg" > $fspath/etc/network/interfaces`;
#	`sudo echo "route add default gw $gateip" > $fspath/etc/myprofile`;
	`sudo cat /etc/resolv.conf > $fspath/etc/resolv.conf`;

	my $a2 = "setenv bootargs " .
		"console=ttyS0,115200n8 " .
		"boardmodel=SBC35X-B1-1880-LUAC0 " .
		"vram=12M omapfb.mode=dvi:1024x768MR-16\@60 omapdss.def_disp=dvi " .
		"mem=99M\@0x80000000 mem=128M\@0x88000000 " .
		"mpurate=1000 " .
		"root=/dev/nfs nfsroot=$myip:$fspath,port=2049 " .
		"ip=$armip:$myip:$gateip:255.255.255.0:arm:eth0 " .
		""
		#ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>
		#"boardmodel=SBC35X-B1-1880-LUAC0 " 
		;
	uboot $a2;
}

if ($args eq 'args8168') {
	$armip = $ENV{'ip8168'};
	my $afs = $fs eq 'mmc' ? 
		"root=/dev/mmcblk0p2 " :
		"root=/dev/nfs nfsroot=$myip:$fspath,port=2049 ".
		"ip=$armip:$myip:$gateip:255.255.255.0:arm:eth0 " 
		;
	$afs = "$afs single" if $fs eq 'tifs-8168';
	my $a2 = "setenv bootargs " .
		"console=ttyO2,115200n8 rootwait rw mem=256M earlyprintk " .
		"notifyk.vpssm3_sva=0xBF900000 vram=50M ti816xfb.vram=0:16M,1:16M,2:6M " .
		$afs
		;
	uboot $a2;
}

if ($uimage eq 'nand') {
#uboot "mmc init; fatload mmc 0 \${loadaddr} uImage; bootm \${loadaddr}";
	uboot "nand read \${loadaddr} 280000 400000";
} else {
	uboot "setenv serverip $myip";
	uboot "setenv ipaddr $armip";
	`cp $uimage /var/lib/tftpboot`;
	my $b = `basename $uimage`;
	uboot "tftp \${loadaddr} $b";
}
$e->send("bootm \${loadaddr}\n");

if ($cmd eq 'fs') {
	$e->interact();
}

$e->expect(1000000, "-re", "^Welcome");
exit 0

