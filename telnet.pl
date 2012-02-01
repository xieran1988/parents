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
	if ($cmd =~ "expect-interact") {
		$e->send("$cmd\n");
	} else {
		$e->send("$cmd ; echo noweof\n");
		$e->expect(1000000000, '-re', "^noweof") or die 'fuck';
		exit 0;
	}
}
$e->interact();

