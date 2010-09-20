###
### $Release:$
### $Copyright$
### $License$
###

package Specofit;
use strict;
use Data::Dumper;
#use Exporter 'import';
use Exporter;
our @EXPORT = qw(spec_of describe it spec when and_it and_that examples_of scenario
                 before_each after_each before_all after_all
                 invoke_before_each invoke_after_each invoke_before_all invoke_after_all
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


our $_before_all;
our $_after_all;
our $_before_each;
our $_after_each;

sub before_all  (&) { $_before_all  = shift; }
sub after_all   (&) { $_after_all   = shift; }
sub before_each (&) { $_before_each = shift; }
sub after_each  (&) { $_after_each  = shift; }

sub invoke_before_all  { return $_before_all->(@_);  }
sub invoke_after_all   { return $_after_all->(@_);   }
sub invoke_before_each { return $_before_each->(@_); }
sub invoke_after_each  { return $_after_each->(@_);  }


our $current_target;

sub _spec_of {
    my ($envkey, $target, @args) = @_;
    return if $ENV{$envkey} && $target ne $ENV{$envkey};
    my $closure = pop @args;
    local ($_before_all,  $_after_all)  = ($_before_all,  $_after_all);
    local ($_before_each, $_after_each) = ($_before_each, $_after_each);
    $current_target = $target;
    $_before_all->() if $_before_all;
    $closure->($target);
    $_after_all->()  if $_after_all;
    $current_target = undef;
}

sub spec_of {
    return _spec_of('SPEC_OF', @_);
}

sub describe {
    return _spec_of('DESCRIBE', @_);
}

sub examples_of {
    return _spec_of('EXAMPLES_OF', @_);
}

sub scenario {
    return _spec_of('SCENARIO', @_);
}

our $current_desc;

sub _it {
    my ($envkey, $desc, @args) = @_;
    return if $ENV{$envkey} && $desc ne $ENV{$envkey};
    my $closure = pop @args;
    $current_desc = $desc;
    $_before_each->(@args) if $_before_each;
    $closure->();
    $_after_each->(@args)  if $_after_each;
    $current_desc = undef;
}

sub it {
    return _it("IT", @_);
}

sub spec {
    return _it("IT", @_);
}

sub when {
    return _it("WHEN", @_);
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
    ## TODO: remove dependency on external 'diff' command
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
        print "# ---------- $testname\n";
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
    _report _diff($expected, $actual), "$testname (-: expected, +: actual)" unless $result;
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
