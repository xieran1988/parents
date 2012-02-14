#!/usr/bin/perl

my $path = @ARGV[0];
my @a = split /\//, $path;
my $usb = $a[7];
my $net = $a[9];
`echo $usb $net >> /tmp/blog`;
my $mac;
my $ip;
if ($usb eq '2-1.4:1.0') {
	$ip = "192.168.33.122";
	$mac = "00:11:22:33:44:01";
}
if ($usb eq '2-1.3:1.0') {
	$ip = "192.168.2.122";
	$mac = "00:11:22:33:44:12";
}
system("
(
(
sleep 1
echo $ip $mac >> /tmp/blog
ifconfig $net >> /tmp/blog
whoami >> /tmp/blog
ifconfig $net down
ifconfig $net hw ether $mac
ifconfig $net $ip netmask 255.255.255.0 up
) &
) &
");

