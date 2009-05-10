use strict;
use Tenjin;
use Data::Dumper;
use TestHelper;
use YAML::Syck;

my $s = Tenjin::Util::read_file('test_engine.yaml');
$s = Tenjin::Util::expand_tabs($s);
my $ydoc = YAML::Syck::Load($s);

$ydoc = TestHelper::manipulate_testdata($ydoc);
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



## --------------------

sub _test_basic {
    my $testname = 'test_basic';
    my $data = $TESTDATA->{basic};
    my @caller = caller(1);
    my $funcname = $caller[3];
    $funcname =~ m/test_basic_(.*)/;
    my @info = split('_', $1);
    my $action = $info[0];                 # 'list', 'show', 'create', or 'edit'
    my $shortp = $info[1] ne 'filename';   # template short name or filename
    my $layoutp = $info[2] ne 'nolayout';  # use layout or not

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
        assert_eq($expected, $actual);
    };
    report_error($@, $testname);

    ## teardown
    remove_files('user_', 'footer');
}

# fileame, nolayout
sub test_basic_list_filename_nolayout   { _test_basic(); }
sub test_basic_show_filename_nolayout   { _test_basic(); }
sub test_basic_create_filename_nolayout { _test_basic(); }
sub test_basic_edit_filename_nolayout   { _test_basic(); }

# shortname, nolayout
sub test_basic_list_shortname_nolayout   { _test_basic(); }
sub test_basic_show_shortname_nolayout   { _test_basic(); }
sub test_basic_create_shortname_nolayout { _test_basic(); }
sub test_basic_edit_shortname_nolayout   { _test_basic(); }

# filename, withlayout
sub test_basic_list_filename_withlayout   { _test_basic(); }
sub test_basic_show_filename_withlayout   { _test_basic(); }
sub test_basic_create_filename_withlayout { _test_basic(); }
sub test_basic_edit_filename_withlayout   { _test_basic(); }

# shortname, withlayout
sub test_basic_list_shortname_withlayout   { _test_basic(); }
sub test_basic_show_shortname_withlayout   { _test_basic(); }
sub test_basic_create_shortname_withlayout { _test_basic(); }
sub test_basic_edit_shortname_withlayout   { _test_basic(); }


## --------------------

sub test_capture_and_echo {
    my $testname = 'test_capture_and_echo';
    my $data = $TESTDATA->{$testname};

    my $layout   = $data->{layout};
    my $content  = $data->{content};
    my $expected = $data->{expected};
    my $layout_filename = 'user_layout.plhtml';
    my $content_filename = 'user_content.plhtml';

    eval {
        Tenjin::Util::write_file($layout_filename, $layout);
        Tenjin::Util::write_file($content_filename, $content);
        my $engine = new Tenjin::Engine({prefix=>'user_', postfix=>'.plhtml', layout=>':layout'});
        my $context = { items=>['AAA', 'BBB', 'CCC'] };
        my $actual = $engine->render(':content', $context);
        assert_eq($expected, $actual, $testname);
    };
    report_error($@, $testname);
    remove_files($layout_filename, $content_filename);
}


sub test_captured_as {
    my $testname = 'test_captured_as';
    my $data = $TESTDATA->{$testname};
    my $context = $data->{context};
    my $expected = $data->{expected};
    my @names = ('baselayout', 'customlayout', 'content');
    eval {
        for my $name (@names) {
            Tenjin::Util::write_file("$name.plhtml", $data->{$name});
        }
        my $engine = new Tenjin::Engine({postfix=>'.plhtml'});
        my $actual = $engine->render(':content', $context);
        assert_eq($expected, $actual, $testname);
    };
    report_error($@, $testname);
    remove_files(\@names);
}


sub test_local_layout {
    my $testname = 'test_local_layout';
    my $data = $TESTDATA->{$testname};
    my $context = $data->{context};
    my @names = ('layout_html', 'layout_xhtml', 'content_html');
    eval {
        for my $name (@names) {
            Tenjin::Util::write_file("local_$name.plhtml", $data->{$name});
        }
        my $engine = new Tenjin::Engine({prefix=>'local_', postfix=>'.plhtml', layout=>':layout_html'});
        my $name = 'content_html';
        my($content_html, $actual);
        ## default layout
        $content_html = $data->{$name};
        Tenjin::Util::write_file("local_$name.plhtml", $content_html);
        $actual = $engine->render(':content_html', $context);
        assert_eq($data->{expected_html}, $actual, $testname);
        ## _layout = ':layout_xhtml'
        sleep(1);
        $content_html = $data->{$name} . '<?pl $_context->{_layout} = ":layout_xhtml"; ?>';
        Tenjin::Util::write_file("local_$name.plhtml", $content_html);
        $actual = $engine->render(':content_html', $context);
        assert_eq($data->{expected_xhtml}, $actual, $testname);
        ## _layout = 0
        sleep(1);
        $content_html= $data->{$name} . '<?pl $_context->{_layout} = 0; ?>';
        Tenjin::Util::write_file("local_$name.plhtml", $content_html);
        $actual = $engine->render(":content_html", $context);
        assert_eq($data->{expected_nolayout}, $actual, $testname);
    };
    report_error($@, $testname);
    remove_files('local_');
}


sub test_cachefile {
    my $testname = 'test_cachefile';
    my $data = $TESTDATA->{$testname};
    my $expected = $data->{expected};
    my $context = $data->{context};
    eval {
        Tenjin::Util::write_file('layout.plhtml',         $data->{layout});
        Tenjin::Util::write_file('account_create.plhtml', $data->{page});
        Tenjin::Util::write_file('account_form.plhtml',   $data->{form});
        my $args = { prefix=>'account_', postfix=>'.plhtml', layout=>'layout.plhtml' };
        ## not caching
        my %args1 = %$args;
        $args1{cache} = 0;
        my $engine = new Tenjin::Engine(\%args1);
        my $actual = $engine->render(':create', $context);
        assert_eq($expected, $actual, $testname);
        assert_not_exist('account_create.plhtml.cache', $testname);
        assert_not_exist('account_form.plhtml.cache', $testname);
        assert_not_exist('layout.plhtml.cache', $testname);
        ## file caching
        my %args2 = %$args;
        $args2{cache} = 1;
        my $engine = new Tenjin::Engine(\%args2);
        my $actual = $engine->render(':create', $context);
        assert_eq($expected, $actual, $testname);
        assert_exist('account_create.plhtml.cache', $context, $testname);
        assert_exist('account_form.plhtml.cache', $context, $testname);
        assert_exist('layout.plhtml.cache', $testname);
        unlink('account_create.plhtml.cache');
        unlink('account_form.plhtml.cache');
    };
    report_error($@, $testname);
    remove_files('account_', 'layout.plhtml');
}


sub test_change_layout {
    my $testname = 'test_change_layout';
    my $data = $TESTDATA->{$testname};
    my $expected = $data->{expected};
    my @names = qw(baselayout customlayout content);
    eval {
        for my $name (@names)  {
            Tenjin::Util::write_file("$name.plhtml", $data->{$name});
        }
        my $engine = new Tenjin::Engine({layout=>'baselayout.plhtml'});
        my $actual = $engine->render('content.plhtml');
        assert_eq($expected, $actual, $testname);
    };
    report_error($@, $testname);
    remove_files(@names);
}


sub test_context_scope {
    my $testname = 'test_context_scope';
    my $data = $TESTDATA->{$testname};
    my $expected = $data->{expected};
    eval {
        Tenjin::Util::write_file('base.plhtml', $data->{base});
        Tenjin::Util::write_file('part.plhtml', $data->{part});
        my $engine = new Tenjin::Engine({postfix=>'.plhtml'});
        my $actual = $engine->render(':base');
        assert_eq($expected, $actual, $testname);
    };
    report_error($@, $testname);
    remove_files('base', 'part');
}


sub test_template_args {
    my $testname = 'test_template_args';
    my $data = $TESTDATA->{$testname};
    my $expected = $data->{expected};
    my $errormsg = $data->{errormsg};
    my $exception = eval($data->{exception});
    my $context = $data->{context};
    my $filename = 'content.plhtml';
    my $args1;
    my $args2;
    Tenjin::Util::write_file($filename, $data->{content});
    $Tenjin::USE_STRICT = 1;
    eval { ## when no cache file exists
        assert_not_exist("$filename.cache", $testname);
        my $engine = new Tenjin::Engine({cache=>1});
        $args1 = $engine->get_template($filename)->{args};
    };
    my $actual = $@;
    $actual   =~ s/\(eval \d+\)/\(eval\)/;
    $errormsg =~ s/\(eval \d+\)/\(eval\)/;
    assert_eq($errormsg, $actual);
    $@ = undef();
    eval { ## when cache file exists
        assert_exist("$filename.cache", $testname);
        my $engine = new Tenjin::Engine({cache=>1});
        $args2 = $engine->get_template($filename)->{args};
    };
    $actual = $@;
    $actual =~ s/\(eval \d+\)/\(eval\)/;
    assert_eq($errormsg, $actual);
    #report_error($@, $testname);
    remove_files($filename);
}


sub _test_template_path {
    my ($arg1, $arg2, $arg3) = @_;   # layout, body, footer
    my $testname = 'test_template_path';
    my $data = $TESTDATA->{$testname};
    my $basedir = 'test_templates';
    my @keys = ($arg1, $arg2, $arg3);
    eval {
        ## setup dir
        for my $dir ($basedir, "$basedir/common", "$basedir/user") {
            mkdir($dir) unless -d $dir;
        }
        ## setup files
        my %d = (layout=>$arg1, body=>$arg2, footer=>$arg3);
        for my $key (("layout", "body", "footer")) {
            my $filename = "$basedir/common/$key.plhtml";
            Tenjin::Util::write_file($filename, $data->{"common_$key"});
            if ($d{$key} eq 'user') {
                $filename = "$basedir/user/$key.plhtml";
                Tenjin::Util::write_file($filename, $data->{"user_$key"});
            }
        }
        ##
        my $path = ["$basedir/user", "$basedir/common"];
        my $engine = new Tenjin::Engine({postfix=>'.plhtml', path=>$path, layout=>':layout'});
        my $context = { items=>['AAA', 'BBB', 'CCC'] };
        my $actual = $engine->render(':body', $context);
        ##
        my $expected = $data->{"expected_" . join('_', @keys)};
        assert_eq($expected, $actual, $testname);
        ##
    };
    report_error($@, $testname);
    #remove_files($filename);
    #`rm -rf $basedir`;
    for my $name (glob("$basedir/**/*")) {
        if (-f $name) { unlink($name); }
    }
    for my $name ("$basedir/common", "$basedir/user", $basedir) {
        if (-d $name) { rmdir($name); }
    }
}


sub test_template_path_common_common_common {
    _test_template_path('common', 'common', 'common');
}
sub test_template_path_user_common_common {
    _test_template_path('user',   'common', 'common');
}
sub test_template_path_common_user_common {
    _test_template_path('common', 'user',   'common');
}
sub test_template_path_user_user_common {
    _test_template_path('user',   'user',   'common');
}
sub test_template_path_common_common_user {
    _test_template_path('common', 'common', 'user');
}
sub test_template_path_user_common_user {
    _test_template_path('user',   'common', 'user');
}
sub test_template_path_common_user_user {
    _test_template_path('common', 'user',   'user');
}
sub test_template_path_user_user_user {
    _test_template_path('user',   'user',   'user');
}


sub test_preprocessor {
    my $testname = 'test_preprocessor';
    my $data = $TESTDATA->{$testname};
    my $form = $data->{form};
    my $create = $data->{create};
    my $update = $data->{update};
    my $layout = $data->{layout};
    my $context = $data->{context};
    #
    eval {
        my @basenames = qw(form create update layout);
        my @filenames = ();
        for my $basename (@basenames) {
            my $filename = "prep_$basename.plhtml";
            push(@filenames, $filename);
            Tenjin::Util::write_file($filename, $data->{$basename});
        }
        my $engine = new Tenjin::Engine({prefix=>'prep_', postfix=>'.plhtml', layout=>':layout', preprocess=>1});
        ## create (<?pl include() ?>)
        my $context = { title=>'Create', action=>'create', params=>{'state'=>'NY'} };
        my $actual = $engine->render(':create', $context); # 1st
        assert_eq($data->{expected1}, $actual);
        $context->{params} = {'state'=>'xx'};
        $actual = $engine->render(':create', $context); # 2nd
        #assert_eq($data->{expected1}, $actual);
        my $expected = $data->{expected1};
        $expected =~ s/ checked="checked"//;
        assert_eq($expected, $actual);
        ## update (<?PL include() ?>)
        $context = { title=>'Update', action=>'update', params=>{'state'=>'NY'} };
        $actual = $engine->render(':update', $context);  # 1st
        assert_eq($data->{expected2}, $actual);
        $context->{params} = {'state'=>'xx'};
        $actual = $engine->render(':update', $context);  # 2nd
        assert_eq($data->{expected2}, $actual);  # not changed!
        #$expected = $data->{expected2};
        #$expected =~ s/ checked="checked"//;
        #assert_eq($expected, $actual);
    };
    report_error($@, $testname);
    remove_files('prep_');
}



## --------------------

# filename, nolayout
test_basic_list_filename_nolayout();
test_basic_show_filename_nolayout();
test_basic_create_filename_nolayout();
test_basic_edit_filename_nolayout();

# shortname, nolayout
test_basic_list_shortname_nolayout();
test_basic_show_shortname_nolayout();
test_basic_create_shortname_nolayout();
test_basic_edit_shortname_nolayout();

# filename, withlayout
test_basic_list_filename_withlayout();
test_basic_show_filename_withlayout();
test_basic_create_filename_withlayout();
test_basic_edit_filename_withlayout();

# shortname, withlayout
test_basic_list_shortname_withlayout();
test_basic_show_shortname_withlayout();
test_basic_create_shortname_withlayout();
test_basic_edit_shortname_withlayout();


## --------------------

test_capture_and_echo();
test_captured_as();
test_local_layout();
test_cachefile();
test_change_layout();
test_context_scope();
test_template_args();
test_preprocessor();

## --------------------

test_template_path_common_common_common();
test_template_path_user_common_common();
test_template_path_common_user_common();
test_template_path_user_user_common();
test_template_path_common_common_user();
test_template_path_user_common_user();
test_template_path_common_user_user();
test_template_path_user_user_user();

