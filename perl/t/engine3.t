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
use Test::More tests=>34;
use Specofit;
use File::Path;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


spec_of "Tenjin::Engine->cachename", sub {
    my $target = $_[0];

    my $e = Tenjin::Engine->new();

    spec "return cache file path.", sub {
        should_eq($e->cachename('foo.plhtml'), 'foo.plhtml.cache', $target);
    };

};


spec_of "Tenjin::Engine->to_filename", sub {
    my $target = $_[0];

    my $e = Tenjin::Engine->new({prefix=>'_views/', postfix=>'.plhtml'});

    spec "if template_name starts with ':', add prefix and postfix to it.", sub {
        should_eq($e->to_filename(':index'), '_views/index.plhtml', $target);
    };

    spec "if template_name doesn't start with ':', just return it.", sub {
        should_eq($e->to_filename('index'), 'index', $target);
    };

};


sub _with_dummy_files {
    my ($fnames, $block) = @_;
    $fnames = [$fnames] if ref($fnames) ne 'ARRAY';
    for (@$fnames) {
        write_file($_, "AAA");
    }
    eval { $block->(); };
    for (@$fnames) {
        unlink($_) if -f $_;
    }
    die $@ if $@;
}


spec_of "Tenjin::Engine->_timestamp_changed", sub {
    my $target = $_[0];

    my $e = Tenjin::Engine->new();
    my $fname = '_engine_t.plhtml';
    Tenjin::Util::write_file($fname, 'AAA');
    my $t = Tenjin::Template->new($fname);

    _with_dummy_files $fname, sub {

        my $mtime = (stat $fname)[9];

        spec "if checked within a sec, skip timestamp check and return false.", sub {
            $t->{timestamp} = $mtime + 5;   # template timestamp is different from file
            $t->{_last_checked_at} = time() - 1.0;
            should_be_undef(scalar($e->_timestamp_changed($t)), $target);  # fails. why?
        };

        spec "if timestamp is same as file, return false.", sub {
            $t->{timestamp} = $mtime;       # template timestamp is same as file
            $t->{_last_checked_at} = undef;
            should_be_undef(scalar($e->_timestamp_changed($t)), $target);
            should_be_true($t->{_last_checked_at}, $target);      # _last_checked_at is set
            ok( (time() - $t->{_last_checked_at}) < 0.01 );
        };

        spec "if timestamp is changed, return true.", sub {
            $t->{_last_checked_at} = undef;
            $t->{timestamp} = $mtime - 1;   # template timestamp is different from file
            should_be_true($e->_timestamp_changed($t), $target);
        };

    };

};


spec_of "Tenjin::Engine->_get_template_in_memory", sub {
    my $target = $_[0];

    my $e = Tenjin::Engine->new();
    my $t = Tenjin::Template->new();
    my $fname = '_get_template.plhtml';
    $t->{filename} = $fname;

    _with_dummy_files $fname, sub {

        my $mtime = (stat $fname)[9];

        spec "if template object is not in memory cache then return undef.", sub {
            should_be_undef(scalar $e->_get_template_in_memory($fname), $target);
        };

        spec "if timestamp is not set, don't check timestamp and return it.", sub {
            ! $t->{timestamp}  or die;
            $e->{_templates}->{$fname} = $t;
            my $ret = $e->_get_template_in_memory($fname);
            should_eq(ref($ret), 'Tenjin::Template', $target);
        };

        spec "if timestamp of template file is not changed, return it.", sub {
            $t->{timestamp} = $mtime;
            $e->{_templates}->{$fname} = $t;
            my $ret = $e->_get_template_in_memory($fname);
            should_eq(ref($ret), 'Tenjin::Template', $target);
        };

        spec "if timestamp of template file is changed, clear it and return undef.", sub {
            $t->{_last_checked_at} = undef;
            $t->{timestamp} = $mtime - 1;
            should_be_true($e->{_templates}->{$fname}, $target);
            my $ret = $e->_get_template_in_memory($fname);
            should_be_false(scalar $ret, $target);
            should_be_false(scalar $e->{_templates}->{$fname}, $target);
        };

    };

};


spec_of "Tenjin::Engine->_get_template_in_cache", sub {
    my $target = $_[0];

    my $fpath = '_t_in_cache.plhtml';
    my $cpath = $fpath + '.cache';

    _with_dummy_files [$fpath, $cpath], sub {

        write_file($fpath, '<p>Hello [=$name=]!</p>');
        my $t = Tenjin::Template->new($fpath);
        my $e = Tenjin::Engine->new();
        unlink($cpath) if -f $cpath;

        spec "if template is not found in cache file, return nil.", sub {
            should_be_undef(scalar $e->_get_template_in_cache($fpath, $cpath . '.xxx'), $target);
        };

        spec "if cache returns script and args then build a template object from them.", sub {
            my $ts = time();
            $t->{timestamp} = $ts;
            $e->{cache}->save($cpath, $t);
            should_exist($cpath, $target);
            my $ret = $e->{cache}->load($cpath);
            should_eq(ref($ret), 'HASH', $target);
            $ret = $e->_get_template_in_cache($fpath, $cpath);
            should_eq(ref($ret), 'Tenjin::Template', $target);
        };

        spec "if timestamp is not changed then return it.", sub {
            my $ts = time();
            $t->{timestamp} = $ts;
            $e->{cache}->save($cpath, $t);
            my $ret = $e->_get_template_in_cache($fpath, $cpath);
            should_eq(ref($ret), 'Tenjin::Template', $target);
        };

        spec "if timestamp of template is changed then ignore it.", sub {
            my $ts = time();
            $t->{timestamp} = $ts;
            $e->{cache}->save($cpath, $t);
            utime($ts+1, $ts+1, $fpath);
            should_be_undef(scalar $e->_get_template_in_cache($fpath, $cpath), $target);
        };

    };

};


spec_of "Tenjin::Engine->_preprocess", sub {
    my $target = $_[0];

    my $e = Tenjin::Engine->new();

    spec "preprocess input with _context and return result.", sub {
        my $ret = $e->_preprocess('<<[*=$name=*]>><<[=$name=]>>', undef, {name=>'SOS'});
        should_eq($ret, '<<SOS>><<[=$name=]>>', $target);
    };

};


spec_of "Tenjin::Engine->_create_template", sub {
    my $target = $_[0];

    my $e = Tenjin::Engine->new();

    spec "create template object and return it.", sub {
        my $ret = $e->_create_template();
        should_eq(ref($ret), 'Tenjin::Template', $target);
        should_be_undef(scalar $ret->{script}, $target);
    };

    spec "if input is specified then convert it into script.", sub {
        my $ret = $e->_create_template('<p>[=$name=]</p>', 'foo.plhtml');
        should_eq(ref($ret), 'Tenjin::Template', $target);
        should_eq($ret->{script}, 'my $_buf = ""; my $_V;  $_buf .= q`<p>` . (($_V = ($name)) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</p>`;  $_buf;'."\n", $target);
    };

};


spec_of "Tenjn::Engine->get_template", sub {
    my $target = $_[0];

    my $fpath = '_get_template_test.plhtml';
    my $cpath = $fpath . '.cache';
    my $e = Tenjin::Engine->new({postfix=>'.plhtml'});
    my $t;

    _with_dummy_files [$fpath, $cpath], sub {

        unlink($cpath) if -f $cpath;
        write_file($fpath, '<?pl #@ARGS name ?>'."\n".'<<[=$name=]>><<[*=$name=*]]>>');

        spec "accept template name such as :index.", sub {
            $t = $e->get_template(':_get_template_test');
            should_eq(ref($t), 'Tenjin::Template', $target);
        };

        spec "if template object is in memory cache then return it.", sub {
            $e->{_templates}->{$fpath}  or die;
            rename($cpath, $cpath.'.bak');
            $t = $e->get_template(':_get_template_test');
            should_eq(ref($t), 'Tenjin::Template', $target);
            rename($cpath.'.bak', $cpath);
        };

        spec "if template file is not found then raise TemplateNotFoundError.", sub {
            ! $@  or die;
            eval { $e->get_template("_foobar.xxx"); };
            should_match(scalar($@), scalar(/^_foobar\.xxx: template not found\. \(path=\[\]\)/), $target);
            $@ = undef;
        };
        spec "if template is cached in file then store it into memory and return it.", sub {
            -f $cpath  or die;
            $e->{_templates}->{$fpath} = undef;
            ! $e->{_templates}->{$fpath}  or die;
            $t = $e->get_template(':_get_template_test');
            should_eq(ref($t), 'Tenjin::Template', $target);
            should_be_true($e->{_templates}->{$fpath}, $target);
        };

        spec "get template content and timestamp", sub {
            #
        };

        spec "if preprocess is enabled then preprocess template file.", sub {
            unlink($cpath);
            my $e2 = Tenjin::Engine->new({preprocess=>1});
            my $s2 = $e2->get_template($fpath, {name=>'SOS'})->{script};
            my $expected = 'my $_buf = ""; my $_V; my $name = $_context->{name}; '."\n"
                         . ' $_buf .= q`<<` . (($_V = ($name)) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`>><<SOS]>>`;  $_buf;'."\n";
            should_eq($s2, $expected, $target);
        };

        spec "if template is not found in memory nor cache then create new one.", sub {
            unlink($cpath) if -f $cpath;
            $e->{_templates}->{$fpath} = undef;
            ! -f $cpath  or die;
            ! $e->{_templates}->{$fpath}  or die;
            my $ret = $e->get_template($fpath);
            should_eq(ref($ret), 'Tenjin::Template', $target);
        };

        spec "save template object into file cache and memory cache.", sub {
            #falldown
            should_exist($cpath, $target);
            should_eq(ref($e->{_templates}->{$fpath}), 'Tenjin::Template', $target);
        };

        spec "return template object.", sub { }

    };

};
