
my $sysrootdir = shift @ARGV;
sub findlib {
	my ($l) = @_;
	if ($l =~ "^-l(.*)") {
		for my $a qw( /usr/lib/i386-linux-gnu /usr/lib ) {
			my $p = "$sysrootdir/$a/lib$1.so";
			return $p if (-e $p);
		}
	}
	$l;
}

print join(" ", map { findlib($_) } @ARGV);

