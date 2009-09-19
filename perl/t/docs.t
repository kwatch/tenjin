##
## $Rev$
## $Release: 0.0.0 $
## $Copyright$
##

use Test::More 'no_plan';
use Tenjin;
use Cwd;
use File::Temp;
use File::Basename qw(basename dirname);
use Data::Dumper;


sub diff {
    my ($expected, $result) = @_;
    my ($f1, $tmp1) = File::Temp::tempfile();
    my ($f2, $tmp2) = File::Temp::tempfile();
    print $f1 $expected;
    print $f2 $result;
    my $diff = `diff -u $tmp1 $tmp2`;
    $diff =~ s/\A.*\n.*\n//;
    close($f1);
    close($f2);
    unlink($tmp1);
    unlink($tmp2);
    return $diff;
}

sub do_test {
    my ($name) = @_;

    my $datadir = "data/$name";
    my $currdir = Cwd::getcwd();
    chdir($datadir);

    my @filenames = ();
    #push(@filenames, glob("**/*.result"), glob("**/*.source"));
    push(@filenames, glob("*.result"), glob("*.source"), glob("*/*.result"), glob("*/*.source"));
    @filenames = sort(@filenames);

    for my $filename (@filenames) {
        my $_filename = $filename;
        my $d = dirname($filename);
        if ($d ne '.') {
            chdir($d);
            $filename = basename($filename);
        }
        $_ = Tenjin::Util::read_file($filename);
        next unless s/\A\$ (.*)\n//;
        my $command = $1;
        my $expected = $_;
        my $result = `$command 2>&1`;

        is($result, $expected, $_filename);

        my $diff = $expected eq $result ? undef : &diff($expected, $result);
        if ($diff) {
            print "--------- $filename\n";
            print "$command\n";
            print $diff;
            print "---------\n";
        }
        if ($d ne '.') {
            chdir('..');
        }
    }

    chdir($currdir);

}


my @testnames = @ARGV ? @ARGV : ('users_guide', 'faq', 'examples');
for my $testname (@testnames) {
    print "*** $testname\n";
    do_test($testname);
}
