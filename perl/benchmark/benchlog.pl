use strict;
use Data::Dumper;

my $names = [];
my $table = {};

while (<>) {
    if (/^(\w[-\w]+)\s+([.\d]+)\s+([.\d]+)\s+([.\d]+)\s+([.\d]+)/) {
	my $name = $1;
	my ($utime, $stime, $total, $real) = ($2+0.0, $3+0.0, $4+0.0, $5+0.0);
	my $list = $table->{$name};
	if (! $list) {
	    push(@$names, $name);
	    $table->{$name} = $list = [];
	}
	push(@$list, [$utime, $stime, $total, $real]);
    }
}

print "                          user         sys       total        real\n";
for my $name (@$names) {
    my $tuples = $table->{$name};
    my ($utime, $stime, $total, $real) = (0.0, 0.0, 0.0, 0.0);
    for my $tuple (@$tuples) {
	$utime += $tuple->[0];
	$stime += $tuple->[1];
	$total += $tuple->[2];
	$real  += $tuple->[3];
    }
    #printf("%-18s %11.4f %11.4f %11.4f %11.4f\n", $name, $utime, $stime, $total, $real);
    printf("%-18s %9.2f00 %9.2f00 %9.2f00 %6.0f.0000\n", $name, $utime/10, $stime/10, $total/10, $real/10);
}

#print(Dumper($table));
