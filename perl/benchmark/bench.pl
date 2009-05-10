### $Rev$
### $Release: 0.0.0 $
### $Copyright$


## default values
my $ntimes = 1000;
my $flag_print = 0;
my $use_strict = 0;
my $mode = 'class';  # or 'hash'
my @testnames1 = qw[tenjin tenjin-nocache tenjin-reuse];
my @testnames2 = qw[tenjin-tmpl tenjin-tmpl-cache tenjin-tmpl-reuse tenjin-defun tenjin-compile];
my @testnames3 = qw[tt tt-reuse htmltmpl htmltmpl-reuse];
my @testnames_all = ();
push(@testnames_all, @testnames1, @testnames2, @testnames3);
my @testnames = ();
push(@testnames, @testnames1, @testnames3);
listsub(\@testnames, \@dummy);
#print "@testnames\n";

## packages
push(@INC, '../lib');
use strict;
use Benchmark;
use Getopt::Std;
use Template;
use HTML::Template;
use Tenjin;

## utilities
sub listsub {
    my ($list1, $list2) = @_;
    for my $item (@$list2) {
        my@l = @$list1;
        for (my $i = 0; $i <= $#l; $i++) {
            if ($item eq $list1->[$i]) {
                splice(@$list1, $i, 1);
                last;
            }
        }
    }
    return $list1;
}

## command-line options
my %options;
getopts('hvpwn:m:x:A', \%options) or die($@);
@testnames = @ARGV          if (@ARGV);
@testnames = @testnames_all if ($options{'A'});
$ntimes = 0 + $options{'n'} if ($options{'n'});
$flag_print = 1             if ($options{'p'});
$Tenjin::USE_STRICT = 1     if ($options{'w'});
$mode = $options{'m'}       if ($options{'m'});
$mode == 'hash' || $mode == 'class' or die("-m $mode: invalid mode.");
if ($options{'x'}) {
    my @names = split(',', $options{'x'});
    listsub(\@testnames, \@names);
}
#print "*** debug: @testnames\n";

if ($options{'h'}) {
    print "Usage: python bench.pl [..options..] [testname ...]\n";
    print "  -h:                help\n";
    print "  -n N:              repeat loop N times\n";
    print "  -w:                use strict\n";
    print "  -p:                print output\n";
    print "  -m [hash|class]:   mode\n";
    exit(0);
}


## template filenames
my $template_filenames = {
    tenjin   => 'bench_tenjin.plhtml',
    tt       => 'bench_tt.tt',
    htmltmpl => 'bench_htmltmpl.tmpl',
};


## context
my $context_filename = 'bench_context.pl';
my $s = Tenjin::Util::read_file($context_filename);
my $context1 = eval $s;
$context1->{list} = $context1->{$mode == 'hash' ? 'hash_list' : 'user_list'};
#use Data::Dumper;
#print Dumper($context1);


## context for html::template
my $list = $context1->{list};
my $n = 0;
my @list2 = ();
for my $item (@$list) {
    my %item2 = %$item;
    delete($item2{name2});
    $item2{n} = ++$n;
    $item2{class} = $n % 2 == 0 ? 'even' : 'odd';
    $item2{minus} = $item->{change} < 0.0;
    push(@list2, \%item2);
}
my $context2 = { list=>\@list2 };
#use Data::Dumper;
#print Dumper($context2);


## template-toolkit
sub bench_tt {
    my ($n, $template_filename, $context) = @_;
    my $output;
    while ($n--) {
        my $template = Template->new;
        $output = undef;  # required
        $template->process($template_filename, $context, \$output);
    }
    return $output;
}

## template-toolkit (reuse)
sub bench_tt_reuse {
    my ($n, $template_filename, $context) = @_;
    my $output;
    my $template = Template->new;
    while ($n--) {
        $output = undef;  # required
        $template->process($template_filename, $context, \$output);
    }
    return $output;
}

## html::template
sub bench_htmltmpl {
    my ($n, $template_filename, $context) = @_;
    my $output;
    while ($n--) {
	my $template = new HTML::Template(filename=>$template_filename);
	$template->param($context);
	$output = $template->output;
    }
    return $output;
}

## html::template (reuse)
sub bench_htmltmpl_reuse {
    my ($n, $template_filename, $context) = @_;
    my $output;
    my $template = new HTML::Template(filename=>$template_filename);
    while ($n--) {
	$template->param($context);
	$output = $template->output;
    }
    return $output;
}

## tenjin template
sub bench_tenjin_template {
    my ($n, $template_filename, $context) = @_;
    my $output;
    while ($n--) {
        my $template = new Tenjin::Template($template_filename);
        $output = $template->render($context);
    }
    return $output;
}

## tenjin template (cache)
sub bench_tenjin_template_cache {
    my ($n, $template_filename, $context) = @_;
    my $output;
    my $template = new Tenjin::Template($template_filename);
    my $script = $template->{'script'};
    my $cache_filename = $template_filename . '.cache';
    Tenjin::Util::write_file($cache_filename, $script);
    while ($n--) {
        my $template = new Tenjin::Template();
        $template->{script} = Tenjin::Util::read_file($cache_filename);
        $output = $template->render($context);
    }
    return $output;
}

## tenjin template (reuse)
sub bench_tenjin_template_reuse {
    my ($n, $template_filename, $context) = @_;
    my $output;
    my $template = new Tenjin::Template($template_filename);
    while ($n--) {
        $output = $template->render($context);
    }
    return $output;
}

## tenjin
sub bench_tenjin {
    my ($n, $template_filename, $context) = @_;
    my $output;
    unlink("$template_filename.cache") if (-f "$template_filename.cache");
    while ($n--) {
        my $engine = new Tenjin::Engine();
        $output = $engine->render($template_filename, $context);
    }
    return $output;
}

## tenjin (nocache)
sub bench_tenjin_nocache {
    my ($n, $template_filename, $context) = @_;
    my $output;
    unlink("$template_filename.cache") if (-f "$template_filename.cache");
    while ($n--) {
        my $engine = new Tenjin::Engine({cache=>0});
        $output = $engine->render($template_filename, $context);
    }
    return $output;
}

## tenjin (reuse)
sub bench_tenjin_reuse {
    my ($n, $template_filename, $context) = @_;
    my $output;
    unlink("$template_filename.cache") if (-f "$template_filename.cache");
    my $engine = new Tenjin::Engine();
    while ($n--) {
        $output = $engine->render($template_filename, $context);
    }
    return $output;
}

## tenjin (defun)
sub bench_tenjin_defun {
    my ($n, $template_filename, $context) = @_;
    my $output;
    my $template = new Tenjin::Template($template_filename, {escapefunc=>'Tenjin::Util::escape_xml'});
    my $script = $template->defun('render_tenjin_template', qw[list]);
    #Tenjin::Util::write_file('tenjin_defun.pl', $script);
    eval $script;
    $@ and die($@);
    while ($n--) {
        $output = render_tenjin_template($context);
    }
    return $output;
}


## tenjin (compile)
use Data::Dumper;
sub bench_tenjin_compile {
    my ($n, $template_filename, $context) = @_;
    my $output;
    my $template = new Tenjin::Template($template_filename);
    my $f = $template->compile();
    #Tenjin::Util::write_file('tenjin_defun.pl', $script);
    while ($n--) {
        $output = $template->render($context);
    }
    return $output;
}


## benchmark functions
my $function_table = {
    'tenjin'            => 'bench_tenjin',
    'tenjin-nocache'    => 'bench_tenjin_nocache',
    'tenjin-reuse'      => 'bench_tenjin_reuse',
    'tenjin-defun'      => 'bench_tenjin_defun',
    'tenjin-compile'    => 'bench_tenjin_compile',
    'tenjin-tmpl'       => 'bench_tenjin_template',
    'tenjin-tmpl-cache' => 'bench_tenjin_template_cache',
    'tenjin-tmpl-reuse' => 'bench_tenjin_template_reuse',
    'tt'                => 'bench_tt',
    'tt-reuse'          => 'bench_tt_reuse',
    'htmltmpl'          => 'bench_htmltmpl',
    'htmltmpl-reuse'    => 'bench_htmltmpl_reuse',
};


## create template file
my $header = Tenjin::Util::read_file("templates/_header.html");
my $footer = Tenjin::Util::read_file("templates/_footer.html");
if (grep(/tenjin/, @testnames)) {
    my $body = Tenjin::Util::read_file("templates/bench_tenjin.plhtml");
    Tenjin::Util::write_file("bench_tenjin.plhtml", $header . $body . $footer);
}
if (grep(/tt/, @testnames)) {
    my $body = Tenjin::Util::read_file("templates/bench_tt.tt");
    Tenjin::Util::write_file("bench_tt.tt", $header . $body . $footer);
}
if (grep(/htmltmpl/, @testnames)) {
    my $body = Tenjin::Util::read_file("templates/bench_htmltmpl.tmpl");
    Tenjin::Util::write_file("bench_htmltmpl.tmpl", $header . $body . $footer);
}


## main loop
print "*** n = $ntimes\n";
print "                          user         sys       total        real\n";

for my $testname (@testnames) {
    ## create template file
    my @m = split(/[-_]/, $testname);
    my $template_filename = $template_filenames->{$m[0]};
    $template_filename or die("$testname: unknown test name.");

    ## call benchmark function
    my $funcname = $function_table->{$testname};
    $funcname or die("$testname: unknown test name.");
    $| = 1;
    printf("%-18s", $testname);
    my @start_times = times();
    my $start_time  = time();
    my $context = $context1;
    $context = $context2 if ($testname =~ m/htmltmpl/);
    my $output = eval "$funcname(\$ntimes, \$template_filename, \$context)";
    $@ and die($@);
    #$output = $funcname($ntimes, $template_filename, $context);
    my @end_times = times();
    my $end_time  = time();

    ## result
    my $utime = $end_times[0] - $start_times[0];   # user
    my $stime = $end_times[1] - $start_times[1];   # sys
    my $rtime = $end_time - $start_time;           # real
    #printf("%-18s %10.4f  %10.4f  %10.4f  %10.4f\n",
    #    $testname, $utime, $stime, $utime + $stime, $rtime);
    printf("  %10.4f  %10.4f  %10.4f  %10.4f\n",
           $utime, $stime, $utime + $stime, $rtime);

    ## output
    if ($flag_print) {
        Tenjin::Util::write_file("output.$testname.html", $output);
    }

}
