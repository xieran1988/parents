#!/usr/bin/env perl

use Expect;
#use warnings;
#use strict;

my %sertbl = qw/8168 2 3730 1/;
my %pwrtbl = qw/8168 2 3730 0/;

my $board = $ENV{board};
my $myip = $ENV{myip};
my $gateip = "192.168.0.1";
my $net = "192.168.0.0";
my $armip = $ENV{"ip$board"};

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
exit if exists $ENV{pwroff};
print T $arr[$pwr];
close T;

my $e = new Expect;
$e->spawn("kermit kermrc$sertbl{$board}");
$e->expect(10, '-re', "^--------") or die;
sub end { 
	$e->interact(); exit;
}
end if $ENV{mode} eq 'kermit';

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

if ($ENV{mode} eq 'nfs') {
	my $nfs = `realpath $ENV{nfs}`;
	chomp $nfs;
	`./add-exportfs.sh $nfs`;
	$bootargs .= 
		"root=/dev/nfs nfsroot=$myip:$nfs " .
		"ip=$armip:$myip:$gateip:255.255.255.0:arm:eth0 ";
}
if (exists $ENV{nandboot}) { 
	$bootargs .= "root=ubi0:rootfs ubi.mtd=4 rootfstype=ubifs";
}

if ($ENV{mode} eq 'burn') {
	for my $i (split /,/, $ENV{burn}) {
		if ($i eq 'erase') {
			uboot "nandecc sw";
			uboot "nand erase";
		}
		if ($i eq 'mlo') {
			uboot "nandecc hw";
			uboot "nand erase 0 80000";
			tftp $ENV{mlo};
			uboot "nand write.i \${loadaddr} 0 80000";
		}
		if ($i eq 'uboot') {
			uboot "nandecc sw";
			uboot "nand erase 80000 160000";
			tftp $ENV{uboot};
			uboot "nand write.i \${loadaddr} 80000 160000"
		}
		if ($i eq 'kernmmc') {
			uboot "mmc init";
			uboot "fatload mmc 0:1 80000000 uImage"; 
			uboot "nandecc sw";
			uboot "nand erase 280000 400000";
			uboot "nand write.i 80000000 280000 400000";
		}
		if ($i eq 'kern') {
			uboot "nandecc sw";
			uboot "nand erase 280000 400000";
			tftp $ENV{kern};
			uboot "nand write.i \${loadaddr} 280000 400000";
		}
		if ($i eq 'ubi') {
			uboot "nandecc sw";
			uboot "nand erase 680000 8000000";
			tftp $ENV{ubi};
			uboot "nand write.i \${loadaddr} 680000 \${filesize}";
		}
	}
}

if (!exists $ENV{defenv}) {
	uboot "setenv nandargs setenv bootargs $bootargs $ENV{bootparm}";
}
uboot "saveenv" if exists $ENV{'saveenv'};

exit if $ENV{mode} eq 'burn';
end if $ENV{mode} eq 'uboot';

if ($ENV{loaduboot}) {
	tftp $ENV{loaduboot};
	$e->send("go \${loadaddr}\n");
	waituboot;
}

if ($ENV{kern}) {
	tftp $ENV{kern};
} else {
	uboot "nand read \${loadaddr} 280000 400000";
}
$e->send("run nandargs; bootm \${loadaddr}\n");

end;

