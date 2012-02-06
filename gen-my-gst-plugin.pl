#!/usr/bin/perl

my $fo = shift @ARGV;
my $po = shift @ARGV;
my $pn = shift @ARGV;
my $fn = $pn;

print "from file $fo.[ch]\n";
print "to file $fn.[ch]\n";
print "old pattern $po\n";
print "new pattern $pn\n";

my $Un = uc($pn);
my $un = ucfirst($pn);
my $Uo = uc($po);
my $uo = ucfirst($po);

my $i;
my @s = (
	"s/{p}/$pn/g",
);
for (@ARGV) {
	my $old = $_;
	$old =~ s/{p}/$po/g;
	$old =~ s/{U}/$Uo/g;
	$old =~ s/{u}/$uo/g;
	my $new = $_;
	$new =~ s/{p}/$pn/g;
	$new =~ s/{U}/$Un/g;
	$new =~ s/{u}/$un/g;
	$i++;
	push @s, "s/{a$i}/$new/g";
	push @s, "s/$old/$new/g";
}
my $ss = join(";", @s);
print "sedstr: $ss\n";
`cp $fo.c $fn.c`;
`cp $fo.h $fn.h`;
`sed -i '$ss' $fn.*`;
`sed '$ss' $ENV{'parentsdir'}/gstregplugin.c >> $fn.c`;

