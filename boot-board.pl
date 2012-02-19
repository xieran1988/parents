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
my $tiuboot = $ARGV[6] if $ARGV[6];

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
$args =~ /args(....)/;
my $armip = $ENV{"ip$1"};

uboot "setenv serverip $myip";
uboot "setenv ipaddr $armip";

if ($cmd =~ /ti-uboot/) {
	`cp $tiuboot /var/lib/tftpboot`;
	my $b = `basename $tiuboot`;
	uboot "tftp \${loadaddr} $b";
	$e->send("go \${loadaddr}\n");
	$e->expect(10, '-re', "^Hit") or die;
	$e->send("c");
	uboot_exp;
	uboot "setenv serverip $myip";
	uboot "setenv ipaddr $armip";
	uboot "setenv ethaddr 00:11:22:33:44:55";
}

if ($args eq 'args3530' || $args eq 'args3730') {
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
	`sudo rm -rf $fspath/etc/resolv.conf`;
	`sudo cp /etc/resolv.conf $fspath/etc/resolv.conf`;

	my $model = $args eq 'args3730' ? 
		'EVM37X-B1-3990-LUAC0' : 
		'SBC35X-B1-1880-LUAC0';

	my $tty = $cmd =~ /ti-uboot/ ? "ttyO2" : "ttyS0";

	my $mem = $args =~ /3530/ ? 
		"mem=99M\@0x80000000 mem=128M\@0x88000000 " :
		"mem=80M";

	my $a2 = "setenv bootargs " .
		"console=$tty,115200n8 " .
		"boardmodel=$model " .
		"vram=12M omapfb.mode=dvi:1024x768MR-16\@60 omapdss.def_disp=dvi " .
		"$mem " .
		"mpurate=1000 " .
		"root=/dev/nfs nfsroot=$myip:$fspath,port=2049 " .
		"ip=$armip:$myip:$gateip:255.255.255.0:arm:eth0 " .
		""
		#ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>
		#"boardmodel=SBC35X-B1-1880-LUAC0 " 
		#"boardmodel=SBC35X-B1-1880-LUAC0 " 
		;
	uboot $a2;
}

if ($args eq 'args8168') {
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
	`cp $uimage /var/lib/tftpboot`;
	my $b = `basename $uimage`;
	uboot "tftp \${loadaddr} $b";
}
$e->send("bootm \${loadaddr}\n");

if ($cmd =~ /fs/) {
	$e->interact();
}

$e->expect(1000000, "-re", "^Welcome");
exit 0

set line /dev/ttyUSB0
set speed 115200
set carrier-watch off
set handshake none
set flow-control none
robust
connect
#!/usr/bin/env perl

use Expect;
use warnings;
use strict;

my $ip = $ARGV[0];
my $cmd = $ARGV[1];
my $e = new Expect;
$e->spawn("telnet $ip");
$e->expect(2, '-re', "^Escape") or exit 123;
$e->expect(2, '-re', "# ") or exit 123;
$e->send("cd /root\n");
$e->expect(2, '-re', "# ") or exit 123;
if ($cmd) {
#	if ($cmd =~ "expect-interact") {
	if (1) {
		$e->send("$cmd\n");
	} else {
		$e->send("$cmd ; echo noweof\n");
		$e->expect(1000000000, '-re', "^noweof") or die 'fuck';
		exit 0;
	}
}
$e->interact();

