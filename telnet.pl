#!/usr/bin/env perl

use Expect;
use warnings;
use strict;

my $e = new Expect;
$e->spawn("telnet $ENV{ip}");
if ($e->expect(2, '-re', "^Escape")) {
	$e->expect(2, '-re', "# ") or exit 123;
	$e->send("cd $ENV{cd}\n");
	$e->expect(2, '-re', "# ") or exit 123;
	if (exists $ENV{cmd}) {
		$e->send("$ENV{cmd}\n");
	}
	$e->interact();
}


