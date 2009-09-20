###
### $Release:$
### $Copyright$
### $License$
###

package Specofit;
use strict;
use Data::Dumper;
use Exporter 'import';
our @EXPORT = qw(spec_of describe it and_it and_that examples_of
                 pre_cond pre_task post_task repr
                 should_eq should_be_true should_be_false should_be_undef should_match
                 should_exist should_not_exist should_be_file should_be_dir);
use Test::Simple;
use Test::Builder::Module;
sub import {
    my ($klass, @args) = @_;
    Test::Simple->import(@args) if @args;
    @_ = ($klass);
    goto &{Exporter::import};
}
use File::Temp;
use Data::Dumper;
use Carp;


our $target;

sub spec_of {
    my ($target, $closure) = @_;
    $target = $target;
    if (! $ENV{'SPEC_OF'} || $target eq $ENV{'SPEC_OF'}) {
        main::before_all($target) if defined(&main::before_all);
        $closure->();
        main::after_all($target) if defined(&main::after_all);
    }
    $target = undef;
}

*describe = *spec_of;

sub examples_of {
    my ($target, $closure) = @_;
    $target = $target;
    if (! $ENV{'EXAMPLE_OF'} || $target eq $ENV{'EXAMPLE_OF'}) {
        main::before_all($target) if defined(&main::before_all);
        $closure->();
        main::after_all($target) if defined(&main::after_all);
    }
    $target = undef;
}


sub it {
    my ($desc, $closure) = @_;
    if (! $ENV{'IT'} || $desc eq $ENV{'IT'}) {
        main::before_each($desc) if defined(&main::before_each);
        $closure->();
        main::after_each($desc) if defined(&main::after_each);
    }
}

sub and_it {
    my ($desc, $closure) = @_;
    $closure->();
}

*and_that = *and_it;

sub pre_cond(&) {
    my ($closure) = @_;
    $closure->()  or croak("*** pre_condition failed.");
}

sub pre_task(&) {
    my ($closure) = @_;
    $closure->();
    ! $@  or croak("*** pre_task failed: $@");
};

sub post_task(&) {
    my ($closure) = @_;
    $closure->();
    ! $@  or croak("*** post_task failed: $@");
};


### ----------------------------------------

sub _diff {
    my ($expected, $actual) = @_;
    my ($f1, $tmp1) = File::Temp::tempfile();
    my ($f2, $tmp2) = File::Temp::tempfile();
    print $f1 $expected;
    print $f2 $actual;
    my $diff = `diff -u $tmp1 $tmp2`;
    $diff =~ s/\A.*\n.*\n//;   # delete 1st and 2nd lines
    close $f1;
    close $f2;
    unlink $tmp1, $tmp2;
    return $diff;
}

sub _report {
    my ($content, $testname) = @_;
    if ($content) {
        $content =~ s/^/\# /mg;
        print "# ---------- $testname (-: expected, +: actual)\n";
        print $content;
        print "# ----------\n";
    }
}

sub repr {
    my ($item) = @_;
    my $d = Data::Dumper->new([$item]);
    $d->Indent(0)->Terse(1)->Useqq(1);
    return $d->Dump;
}

#sub ok ($;$) {
#    $CLASS->builder->ok(@_);
#}

sub should_eq {
    my ($actual, $expected, $testname) = @_;
    my $result = $actual eq $expected;
    Test::Simple->builder->ok($result, $testname);
    _report _diff($expected, $actual), $testname unless $result;
}

sub should_be_true {
    my ($actual, $testname) = @_;
    my $result = !! $actual;
    Test::Simple->builder->ok($result, $testname);
    _report "true value expected but got ".repr($actual).".\n", $testname unless $result;
}

sub should_be_false {
    my ($actual, $testname) = @_;
    my $result = ! $actual;
    Test::Simple->builder->ok($result, $testname);
    _report "false value expected but got ".repr($actual).".\n", $testname unless $result;
}

sub should_be_undef {
    my ($actual, $testname) = @_;
    my $result = ! defined($actual);
    Test::Simple->builder->ok($result, $testname);
    _report "undef expected but got ".repr($actual).".\n", $testname unless $result;
}

sub should_match {
    my ($actual, $pattern, $testname) = @_;
    my $result = $actual =~ $pattern;
    Test::Simple->builder->ok($result, $testname);
    _report "expected to match ".repr($pattern)." but not matched.\n", $testname unless $result;
}

sub should_exist {
    my ($path, $testname) = @_;
    my $result = -e $path;
    Test::Simple->builder->ok($result, $testname);
    _report "$path: expected to exist but not found.\n", $testname unless $result;
}

sub should_not_exist {
    my ($path, $testname) = @_;
    my $result = ! -e $path;
    Test::Simple->builder->ok($result, $testname);
    _report "$path: expected not to exist but found.\n", $testname unless $result;
}

sub should_be_file {
    my ($path, $testname) = @_;
    my $result = -f $path;
    Test::Simple->builder->ok($result, $testname);
    _report "$path: expected to be file".(-e $path ? ", but not found." : ".")."\n", $testname unless $result;
}

sub should_be_dir {
    my ($path, $testname) = @_;
    my $result = -d $path;
    Test::Simple->builder->ok($result, $testname);
    _report "$path: expected to be directory".(-e $path ? ", but not found." : ".")."\n", $testname unless $result;
}


1;
