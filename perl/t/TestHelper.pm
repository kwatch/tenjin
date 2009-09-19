package TestHelper;

use File::Temp;
use Test::More 'no_plan';

use Exporter;
@ISA = (Exporter);
@EXPORT = qw(diff manipulate_testdata report assert_eq assert_exist assert_not_exist has_error report_error remove_files);


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


sub manipulate_testdata {
    my ($obj) = @_;
    if (ref($obj) eq 'HASH') {
        for my $key (keys %$obj) {
            my $val = $obj->{$key};
            if ($key =~ /(.*)\*$/) {
                delete($obj->{$key});
                die "** error" unless ref($val) eq 'HASH';
                $obj->{$1} = $val->{perl};
            }
            else {
                $obj->{$key} = manipulate_testdata($val);
            }
        }
    }
    elsif (ref($obj) eq 'ARRAY') {
        my $i = 0;
        for my $val (@$obj) {
            $obj->[$i] = manipulate_testdata($val);
            $i++;
        }
    }
    return $obj;
}


sub report {
    my ($content, $testname) = @_;
    if ($content) {
        print "-------- $testname\n";
        print $content;
        print "--------\n";
    }
}


sub assert_eq {
    my ($expected, $actual, $testname) = @_;
    ok($expected eq $actual);
    unless ($expected eq $actual) {
        my $diff = TestHelper::diff($expected, $actual);
        report($diff, $testname);
        die $testname;
    }
}


sub assert_exist {
    my ($filename, $testname) = @_;
    ok((-f $filename));
    unless (-f $filename) {
        report("'$filename' expected but not found.", $testname);
        die $testname;
    }
}

sub assert_not_exist {
    my ($filename, $testname) = @_;
    ok((! -f $filename));
    if (-f $filename) {
        report("'$filename' expected not to exist but found.", $testname);
        die $testname;
    }
}


sub has_error {
    my ($error, $testname) = @_;
    my $substr = substr($error, 0, length($testname));
    return $error && $substr ne $testname;
}


sub report_error {
    my ($error, $testname) = @_;
    if (has_error($error, $testname)) {
        report($error, $testname);
    }
}


sub remove_files {
    for my $name (@_) {
        for my $filename (glob("$name*")) {
            unlink($filename);
        }
    }
}


1;
