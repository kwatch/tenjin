###
### $Release:$
### $Copyright$
### $License$
###

BEGIN {
    unshift @INC, "t"   if -f "t/Specofit.pm";
    unshift @INC, "lib" if -f "lib/Tenjin.pm";
}

use strict;
use Data::Dumper;
use Test::More tests => 50;
use Specofit;
use YAML::Syck;
use File::Path;
use Tenjin;

my $s = Tenjin::Util::read_file('test_engine.yaml');
$s = Tenjin::Util::expand_tabs($s);
my $ydoc = YAML::Syck::Load($s);

my $TESTDATA = {};
for my $hash (@$ydoc) {
    my $name = $hash->{name};
    $TESTDATA->{$name} = $hash;
}

my $templates = $TESTDATA->{basic}->{templates};
for my $d (@$templates) {
    $d->{filename} =~ s/\.xxhtml$/.plhtml/;
}

#print Dumper($TESTDATA->{basic}->{templates});
#__END__


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;

sub report {
    my ($content, $testname) = @_;
    if ($content) {
        print "-------- $testname\n";
        print $content;
        print "--------\n";
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


## --------------------


examples_of "Test::Engine", sub {

    my $_test_basic  = sub {
        my $action = $_[0];                 # 'list', 'show', 'create', or 'edit'
        my $shortp = $_[1] ne 'filename';   # template short name or filename
        my $layoutp = $_[2] ne 'nolayout';  # use layout or not

        my $testname = "test_basic/".join("/", @_);
        my $data = $TESTDATA->{basic};

        #my @caller = caller(1);
        #my $funcname = $caller[3];
        #$funcname =~ m/test_basic_(.*)/;
        #my @info = split('_', $1);
        #my $action = $info[0];                 # 'list', 'show', 'create', or 'edit'
        #my $shortp = $info[1] ne 'filename';   # template short name or filename
        #my $layoutp = $info[2] ne 'nolayout';  # use layout or not

        ## setup
        my @filenames = ();
        my $templates = $data->{templates};
        for my $hash (@$templates) {
            push(@filenames, $hash->{filename});
            Tenjin::Util::write_file($hash->{filename}, $hash->{content});
        }

        ## test
        eval {
            my $layout = $layoutp ? 'user_layout.plhtml' : undef;
            my $engine = new Tenjin::Engine({prefix=>'user_', postfix=>'.plhtml', layout=>$layout});
            my $context = $data->{contexts}->{$action};
            my $key = 'user_' . $action . ($layout ? '_withlayout' : '_nolayout');
            my $expected;
            my $list = $data->{expected};
            for my $h (@$list) {
                if ($h->{name} eq $key) {
                    $expected = $h->{content};
                    last;
                }
            }
            my $filename = "user_$action.plhtml";
            my $tplname = $shortp ? ":$action" : $filename;
            my $actual = $engine->render($tplname, $context, $layout);
            should_eq($expected, $actual, $testname);
        };
        report_error($@, $testname);
        ## teardown
        post_task {
            unlink glob('user_*'), glob('footer*');
        };
    };

    # filename, nolayout
    $_test_basic->(qw(list   filename nolayout));
    $_test_basic->(qw(show   filename nolayout));
    $_test_basic->(qw(create filename nolayout));
    $_test_basic->(qw(edit   filename nolayout));

    # shortname, nolayout
    $_test_basic->(qw(list   shortname nolayout));
    $_test_basic->(qw(show   shortname nolayout));
    $_test_basic->(qw(create shortname nolayout));
    $_test_basic->(qw(edit   shortname nolayout));

    # filename, withlayout
    $_test_basic->(qw(list   filename withlayout));
    $_test_basic->(qw(show   filename withlayout));
    $_test_basic->(qw(create filename withlayout));
    $_test_basic->(qw(edit   filename withlayout));

    # shortname, withlayout
    $_test_basic->(qw(list   shortname withlayout));
    $_test_basic->(qw(show   shortname withlayout));
    $_test_basic->(qw(create shortname withlayout));
    $_test_basic->(qw(edit   shortname withlayout));

};


## --------------------


spec_of "Tenjin::Engine", sub {

    it "supports start_capture/stop_capture", sub {
        my $testname = 'test_capture_and_echo';
        my $data = $TESTDATA->{$testname};

        my $layout   = $data->{layout};
        my $content  = $data->{content};
        my $expected = $data->{expected};
        my $layout_filename = 'user_layout.plhtml';
        my $content_filename = 'user_content.plhtml';

        pre_task {
            write_file($layout_filename, $layout);
            write_file($content_filename, $content);
        };
        my $engine = new Tenjin::Engine({prefix=>'user_', postfix=>'.plhtml', layout=>':layout'});
        my $context = { items=>['AAA', 'BBB', 'CCC'] };
        my $actual = $engine->render(':content', $context);
        should_eq($expected, $actual, $testname);
        report_error($@, $testname);
        post_task {
            unlink glob("$layout_filename*"), glob("$content_filename*");
        };
    };


    it "supports captured_as", sub {
        my $testname = 'test_captured_as';
        my $data = $TESTDATA->{$testname};
        my $context = $data->{context};
        my $expected = $data->{expected};
        my @names = ('baselayout', 'customlayout', 'content');
        pre_task {
            for my $name (@names) {
                write_file("$name.plhtml", $data->{$name});
            }
        };
        my $engine = new Tenjin::Engine({postfix=>'.plhtml'});
        my $actual = $engine->render(':content', $context);
        should_eq($expected, $actual, $testname);
        report_error($@, $testname);
        post_task {
            for (@names) { unlink glob($_.'*'); }
        };
    };


    it "supports local layout", sub {
        my $testname = 'test_local_layout';
        my $data = $TESTDATA->{$testname};
        my $context = $data->{context};
        my @names = ('layout_html', 'layout_xhtml', 'content_html');
        my $interval = $Tenjin::Engine::TIMESTAMP_INTERVAL;
        pre_task {
            $Tenjin::Engine::TIMESTAMP_INTERVAL = 0;
            for my $name (@names) {
                write_file("local_$name.plhtml", $data->{$name});
            }
        };
        eval {
            my $engine = new Tenjin::Engine({prefix=>'local_', postfix=>'.plhtml', layout=>':layout_html'});
            my $name = 'content_html';
            my($content_html, $actual);
            ## default layout
            $content_html = $data->{$name};
            write_file("local_$name.plhtml", $content_html);
            $actual = $engine->render(':content_html', $context);
            should_eq($data->{expected_html}, $actual, $testname);
            ## _layout = ':layout_xhtml'
            sleep(1);
            $content_html = $data->{$name} . '<?pl $_context->{_layout} = ":layout_xhtml"; ?>';
            write_file("local_$name.plhtml", $content_html);
            $actual = $engine->render(':content_html', $context);
            should_eq($data->{expected_xhtml}, $actual, $testname);
            ## _layout = 0
            sleep(1);
            $content_html= $data->{$name} . '<?pl $_context->{_layout} = 0; ?>';
            write_file("local_$name.plhtml", $content_html);
            $actual = $engine->render(":content_html", $context);
            should_eq($data->{expected_nolayout}, $actual, $testname);
        };
        report_error($@, $testname);
        post_task {
            $Tenjin::Engine::TIMESTAMP_INTERVAL = $interval;
            unlink glob('local_*');
        };
    };


    it "supports cache file", sub {
        my $testname = 'test_cachefile';
        my $data = $TESTDATA->{$testname};
        my $expected = $data->{expected};
        my $context = $data->{context};
        pre_task {
            write_file('layout.plhtml',         $data->{layout});
            write_file('account_create.plhtml', $data->{page});
            write_file('account_form.plhtml',   $data->{form});
        };
        pre_cond { ! -e 'layout.plhtml.cache' };
        pre_cond { ! -e 'account_create.plhtml.cache' };
        pre_cond { ! -e 'account_form.plhtml.cache' };
        eval {
            my $args = { prefix=>'account_', postfix=>'.plhtml', layout=>'layout.plhtml' };
            ## not caching
            my %args1 = %$args;
            $args1{cache} = 0;
            my $engine = new Tenjin::Engine(\%args1);
            my $actual = $engine->render(':create', $context);
            should_eq($expected, $actual, $testname);
            should_not_exist('account_create.plhtml.cache', $testname);
            should_not_exist('account_form.plhtml.cache', $testname);
            should_not_exist('layout.plhtml.cache', $testname);
            ## file caching
            my %args2 = %$args;
            $args2{cache} = 1;
            my $engine = new Tenjin::Engine(\%args2);
            my $actual = $engine->render(':create', $context);
            should_eq($expected, $actual, $testname);
            should_exist('account_create.plhtml.cache', $testname);
            should_exist('account_form.plhtml.cache', $testname);
            should_exist('layout.plhtml.cache', $testname);
            unlink('account_create.plhtml.cache');
            unlink('account_form.plhtml.cache');
        };
        report_error($@, $testname);
        unlink glob('account_*'), glob('layout.plhtml*');
    };


    it "supports layout change", sub {
        my $testname = 'test_change_layout';
        my $data = $TESTDATA->{$testname};
        my $expected = $data->{expected};
        my @names = qw(baselayout customlayout content);
        pre_task {
            for (@names) { write_file("$_.plhtml", $data->{$_}); }
        };
        eval {
            my $engine = new Tenjin::Engine({layout=>'baselayout.plhtml'});
            my $actual = $engine->render('content.plhtml');
            should_eq($expected, $actual, $testname);
        };
        report_error($@, $testname);
        post_task {
            for (@names) { unlink glob($_.'*'); }
        };
    };


    it "supports context scope", sub {
        my $testname = 'test_context_scope';
        my $data = $TESTDATA->{$testname};
        my $expected = $data->{expected};
        pre_task {
            write_file('base.plhtml', $data->{base});
            write_file('part.plhtml', $data->{part});
        };
        eval {
            my $engine = new Tenjin::Engine({postfix=>'.plhtml'});
            my $actual = $engine->render(':base');
            should_eq($expected, $actual, $testname);
        };
        report_error($@, $testname);
        post_task {
            unlink glob('base*'), glob('part*');
        };
    };


    it "supports template argument", sub {
        my $testname = 'test_template_args';
        my $data = $TESTDATA->{$testname};
        my $expected = $data->{expected};
        my $errormsg = $data->{errormsg};
        my $exception = eval($data->{exception});
        my $context = $data->{context};
        my $filename = 'content.plhtml';
        my $args1;
        my $args2;
        pre_task {
            write_file($filename, $data->{content});
        };
        $Tenjin::USE_STRICT = 1;
        eval { ## when no cache file exists
            should_not_exist("$filename.cache", $testname);
            my $engine = new Tenjin::Engine({cache=>1});
            $args1 = $engine->get_template($filename)->{args};
        };
        my $actual = $@;
        should_eq($errormsg, $actual, $testname);
        $@ = undef;
        eval { ## when cache file exists
            should_exist("$filename.cache", $testname);
            my $engine = new Tenjin::Engine({cache=>1});
            $args2 = $engine->get_template($filename)->{args};
        };
        $actual = $@;
        should_eq($errormsg, $actual, $testname);
        #report_error($@, $testname);
        $@ = undef;
        post_task {
            unlink glob("$filename*");
        };
    };

};



examples_of "Tenjin::Engine", sub {

    my $testname = 'test_template_path';
    my $basedir  = 'test_templates';
    my $data = $TESTDATA->{$testname};
    my $_test_template_path = sub {
        my ($arg1, $arg2, $arg3) = @_;   # layout, body, footer
        my @keys = ($arg1, $arg2, $arg3);
        pre_task {
            ## setup dir
            mkpath "$basedir";
            mkpath "$basedir/common";
            mkpath "$basedir/user";
            ## setup files
            my %d = (layout=>$arg1, body=>$arg2, footer=>$arg3);
            for (qw(layout body footer)) {
                write_file("$basedir/common/$_.plhtml", $data->{"common_$_"});
                write_file("$basedir/user/$_.plhtml",   $data->{"user_$_"}) if $d{$_} eq 'user';
            }
        };
        eval {
            ##
            my $path = ["$basedir/user", "$basedir/common"];
            my $engine = new Tenjin::Engine({postfix=>'.plhtml', path=>$path, layout=>':layout'});
            my $context = { items=>['AAA', 'BBB', 'CCC'] };
            my $actual = $engine->render(':body', $context);
            ##
            my $expected = $data->{"expected_" . join('_', @keys)};
            should_eq($expected, $actual, $testname);
        };
        report_error($@, $testname);
        post_task {
            rmtree($basedir);
        };
    };

    $_test_template_path->('common', 'common', 'common');
    $_test_template_path->('user',   'common', 'common');
    $_test_template_path->('common', 'user',   'common');
    $_test_template_path->('user',   'user',   'common');
    $_test_template_path->('common', 'common', 'user');
    $_test_template_path->('user',   'common', 'user');
    $_test_template_path->('common', 'user',   'user');
    $_test_template_path->('user',   'user',   'user');

};



spec_of "Tenjin::Engine", sub {

    it "supports preprocessing", sub {
        my $testname = 'test_preprocessor';
        my $data = $TESTDATA->{$testname};
        my $form = $data->{form};
        my $create = $data->{create};
        my $update = $data->{update};
        my $layout = $data->{layout};
        my $context = $data->{context};
        #
        my @basenames = qw(form create update layout);
        my @filenames = ();
        pre_task {
            for my $basename (@basenames) {
                my $filename = "prep_$basename.plhtml";
                push(@filenames, $filename);
                write_file($filename, $data->{$basename});
            }
        };
        eval {
            my $engine = new Tenjin::Engine({prefix=>'prep_', postfix=>'.plhtml', layout=>':layout', preprocess=>1});
            ## create (<?pl include() ?>)
            my $context = { title=>'Create', action=>'create', params=>{'state'=>'NY'} };
            my $actual = $engine->render(':create', $context); # 1st
            should_eq($data->{expected1}, $actual);
            $context->{params} = {'state'=>'xx'};
            $actual = $engine->render(':create', $context); # 2nd
            #should_eq($data->{expected1}, $actual);
            my $expected = $data->{expected1};
            $expected =~ s/ checked="checked"//;
            should_eq($expected, $actual);
            ## update (<?PL include() ?>)
            $context = { title=>'Update', action=>'update', params=>{'state'=>'NY'} };
            $actual = $engine->render(':update', $context);  # 1st
            should_eq($data->{expected2}, $actual);
            $context->{params} = {'state'=>'xx'};
            $actual = $engine->render(':update', $context);  # 2nd
            should_eq($data->{expected2}, $actual);  # not changed!
            #$expected = $data->{expected2};
            #$expected =~ s/ checked="checked"//;
            #should_eq($expected, $actual);
        };
        report_error($@, $testname);
        post_task {
            unlink glob("prep_*");
        };
    };

};



describe 'Template::Engine', sub {

    my ($main_plhtml, $sub_plhtml, $expected);
    $main_plhtml = <<'END';
	<div>
	<?pl include('sub.plhtml', {x=>10, y=>'foo'}) ?>
	</div>
END
    $main_plhtml =~ s/^\t//mg;
    $sub_plhtml = <<'END';
	<?pl #@ARGS $x, $y ?>
	<p>x=[=$x=]</p>
	<p>y=[=$y=]</p>
END
    $sub_plhtml =~ s/^\t//mg;
    $expected = <<'END';
	<div>
	<p>x=10</p>
	<p>y=foo</p>
	</div>
END
    $expected =~ s/^\t//mg;

    spec_of 'include() macro', sub {
        pre_task {
            write_file('main.plhtml', $main_plhtml);
            write_file('sub.plhtml', $sub_plhtml);
        };
        my $engine = Tenjin::Engine->new();
        my $context = {x=>1};
        my $output = $engine->render('main.plhtml', $context);
        should_eq($output, $expected);
        should_be_false($context->{x});
        should_be_false($context->{y});
        post_task {
            unlink glob('main.plhtml*');
            unlink glob('sub.plhtml*');
        };
    };

};
