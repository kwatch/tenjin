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
use Test::More tests => 39;
use Specofit;
use File::Path;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


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



spec_of "Tenjin::Engine", sub {


    spec_of "->cachename", sub {
        my $target = $_[0];

        my $e = Tenjin::Engine->new();

        spec "return cache file path.", sub {
            is $e->cachename('foo.plhtml'), 'foo.plhtml.cache';
        };

        spec "if lang is provided then add it to cache filename.", sub {
            $e->{lang} = 'fr';
            is $e->cachename('foo.plhtml'), 'foo.plhtml.fr.cache';
        };

    };


    spec_of "->to_filename", sub {
        my $target = $_[0];

        my $e = Tenjin::Engine->new({prefix=>'_views/', postfix=>'.plhtml'});

        spec "if template_name starts with ':', add prefix and postfix to it.", sub {
            is $e->to_filename(':index'), '_views/index.plhtml';
        };

        spec "if template_name doesn't start with ':', just return it.", sub {
            is $e->to_filename('index'), 'index';
        };

    };


    spec_of "->_timestamp_changed", sub {
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
                ok ! $e->_timestamp_changed($t);
            };

            spec "if timestamp is same as file, return false.", sub {
                $t->{timestamp} = $mtime;       # template timestamp is same as file
                $t->{_last_checked_at} = undef;
                ok ! $e->_timestamp_changed($t);
                ok $t->{_last_checked_at};      # _last_checked_at is set
                ok( (time() - $t->{_last_checked_at}) < 0.01 );
            };

            spec "if timestamp is changed, return true.", sub {
                $t->{_last_checked_at} = undef;
                $t->{timestamp} = $mtime - 1;   # template timestamp is different from file
                ok $e->_timestamp_changed($t);
            };

        };

    };


    spec_of "->_get_template_in_memory", sub {
        my $target = $_[0];

        my $e = Tenjin::Engine->new();
        my $t = Tenjin::Template->new();
        my $fname = '_get_template.plhtml';
        $t->{filename} = $fname;

        _with_dummy_files $fname, sub {

            my $mtime = (stat $fname)[9];

            spec "if template object is not in memory cache then return undef.", sub {
                ok ! $e->_get_template_in_memory($fname);
            };

            spec "if timestamp is not set, don't check timestamp and return it.", sub {
                ! $t->{timestamp}  or die;
                $e->{_templates}->{$fname} = $t;
                my $ret = $e->_get_template_in_memory($fname);
                isa_ok $ret, 'Tenjin::Template';
            };

            spec "if timestamp of template file is not changed, return it.", sub {
                $t->{timestamp} = $mtime;
                $e->{_templates}->{$fname} = $t;
                my $ret = $e->_get_template_in_memory($fname);
                isa_ok $ret, 'Tenjin::Template';
            };

            spec "if timestamp of template file is changed, clear it and return undef.", sub {
                $t->{_last_checked_at} = undef;
                $t->{timestamp} = $mtime - 1;
                ok $e->{_templates}->{$fname};
                my $ret = $e->_get_template_in_memory($fname);
                ok ! $ret;
                ok ! $e->{_templates}->{$fname};
            };

        };

    };


    spec_of "->_get_template_in_cache", sub {
        my $target = $_[0];

        my $fpath = '_t_in_cache.plhtml';
        my $cpath = $fpath + '.cache';

        _with_dummy_files [$fpath, $cpath], sub {

            write_file($fpath, '<p>Hello [=$name=]!</p>');
            my $t = Tenjin::Template->new($fpath);
            my $e = Tenjin::Engine->new();
            unlink($cpath) if -f $cpath;

            spec "if template is not found in cache file, return nil.", sub {
                ok ! $e->_get_template_in_cache($fpath, $cpath . '.xxx');
            };

            spec "if cache returns script and args then build a template object from them.", sub {
                my $ts = time();
                $t->{timestamp} = $ts;
                $e->{cache}->save($cpath, $t);
                -f $cpath  or die;
                my $ret = $e->{cache}->load($cpath);
                isa_ok $ret, 'HASH';
                $ret = $e->_get_template_in_cache($fpath, $cpath);
                isa_ok $ret, 'Tenjin::Template';
            };

            spec "if timestamp is not changed then return it.", sub {
                my $ts = time();
                $t->{timestamp} = $ts;
                $e->{cache}->save($cpath, $t);
                my $ret = $e->_get_template_in_cache($fpath, $cpath);
                isa_ok $ret, 'Tenjin::Template';
            };

            spec "if timestamp of template is changed then ignore it.", sub {
                my $ts = time();
                $t->{timestamp} = $ts;
                $e->{cache}->save($cpath, $t);
                utime($ts+1, $ts+1, $fpath);
                ok ! $e->_get_template_in_cache($fpath, $cpath);
            };

        };


    };


    spec_of "->_preprocess", sub {

        my $e = Tenjin::Engine->new();

        spec "preprocess input with _context and return result.", sub {
            my $ret = $e->_preprocess('<<[*=$name=*]>><<[=$name=]>>', undef, {name=>'SOS'});
            is $ret, '<<SOS>><<[=$name=]>>';
        };

    };


    spec_of "->_create_template", sub {
        my $target = $_[0];

        my $e = Tenjin::Engine->new();

        spec "create template object and return it.", sub {
            my $ret = $e->_create_template();
            isa_ok $ret, 'Tenjin::Template';
            ok ! $ret->{script};
        };

        spec "if input is specified then convert it into script.", sub {
            my $ret = $e->_create_template('<p>[=$name=]</p>', 'foo.plhtml');
            isa_ok $ret, 'Tenjin::Template';
            is $ret->{script}, 'my $_buf = ""; my $_V;  $_buf .= q`<p>` . (($_V = ($name)) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</p>`;  $_buf;'."\n";
        };


    };


    spec_of "->get_template", sub {
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
                isa_ok $t, 'Tenjin::Template';
            };

            spec "if template object is in memory cache then return it.", sub {
                $e->{_templates}->{$fpath}  or die;
                rename($cpath, $cpath.'.bak');
                $t = $e->get_template(':_get_template_test');
                isa_ok $t, 'Tenjin::Template';
                rename($cpath.'.bak', $cpath);
            };

            spec "if template file is not found then raise TemplateNotFoundError.", sub {
                ! $@  or die;
                eval { $e->get_template("_foobar.xxx"); };
                like $@, qr`^_foobar\.xxx: template not found\. \(path=\[\]\)`;
                $@ = undef;
            };

            spec "if template is cached in file then store it into memory and return it.", sub {
                -f $cpath  or die;
                $e->{_templates}->{$fpath} = undef;
                ! $e->{_templates}->{$fpath}  or die;
                $t = $e->get_template(':_get_template_test');
                isa_ok $t, 'Tenjin::Template';
                ok $e->{_templates}->{$fpath};
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
                is $s2, $expected;
            };

            spec "if template is not found in memory nor cache then create new one.", sub {
                unlink($cpath) if -f $cpath;
                $e->{_templates}->{$fpath} = undef;
                ! -f $cpath  or die;
                ! $e->{_templates}->{$fpath}  or die;
                my $ret = $e->get_template($fpath);
                isa_ok $ret, 'Tenjin::Template';
            };

            spec "save template object into file cache and memory cache.", sub {
                #falldown
                ok -f $cpath;
                isa_ok $e->{_templates}->{$fpath}, 'Tenjin::Template';
            };

            spec "compile template before saving in order to guess template args from context vars.", sub {
                unlink $cpath;                           # remove cache file
                $e->{_templates}->{$fpath} = undef;      # clear memory cache
                write_file($fpath, "<<[==\$x=]>>\n<<[==\$y=]]>>");   # create new template
                my $context = {x=>10, y=>20};
                my $t = $e->get_template($fpath, $context);
                ok $t->{func};
                isa_ok $t->{args}, 'ARRAY';
                my $keys = join(",", @{$t->{args}});
                if ($keys eq "y,x") {
                    is $keys, "y,x";
                    is $t->{script}, 'my $y = $_context->{y}; my $x = $_context->{x}; my $_buf = ""; my $_V;  $_buf .= q`<<` . ($x) . q`>>'."\n"
                                    .'<<` . ($y) . q`]>>`;  $_buf;'."\n";
                } else {
                    is $keys, "x,y";
                    is $t->{script}, 'my $x = $_context->{x}; my $y = $_context->{y}; my $_buf = ""; my $_V;  $_buf .= q`<<` . ($x) . q`>>'."\n"
                                    .'<<` . ($y) . q`]>>`;  $_buf;'."\n";
                }
                my $cdata = read_file($cpath);
                my $header = "\#pltenjin: $Tenjin::VERSION\n"
                           . "\#args: $keys\n"
                           . "\#timestamp: " . (stat $cpath)[9] . "\n";
                is $cdata, $header."\n".$t->{script};
            };

            spec "return template object.", sub { }

        };

    };


};
