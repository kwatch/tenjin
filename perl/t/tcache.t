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
use Test::More tests => 13;
use Specofit;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


sub _remove_file {
    my ($fname, $block) = @_;
    eval { $block->(); };
    unlink($fname) if -f $fname;
    die $@ if $@;
}


spec_of "Tenjin::FileBaseTemplateCache", sub {


    spec_of "->save", sub {

        my $filepath = '_foobar.plhtml';
        my $cachepath = $filepath . '.cache';

        _remove_file $cachepath, sub {

            my $tcache = Tenjin::FileBaseTemplateCache->new();
            my $input = "<?pl \#\@ARGS name, age ?>\n<p>Hello [=\$name=]!</p>";
            my $template = Tenjin::Template->new();
            $template->convert($input, $filepath);
            my $ts = time() - 30;
            $template->{timestamp} = $ts;

            it "save template script and args into cache file.", sub {
                ok ! -f $cachepath;
                $tcache->save($cachepath, $template);
                my $expected = "#pltenjin: $Tenjin::VERSION\n"
                             . "#args: name,age\n"
                             . "#timestamp: " . $template->{timestamp} . "\n"
                             . "\n"
                             . $template->{script};
                ok -f $cachepath;
                should_eq read_file($cachepath), $expected;
            };

            it "set cache file's mtime to template timestamp.", sub {
                is((stat $cachepath)[9], $ts);
            };

        };

    };


    spec_of "->load", sub {

        my $filepath = '_foobar.plhtml';
        my $cachepath = $filepath +'.cache';

        _remove_file $cachepath, sub {

            my $tcache = Tenjin::FileBaseTemplateCache->new();
            my $input = "<?pl \#\@ARGS name, age ?>\n<p>Hello [=\$name=]!</p>";
            my $template = Tenjin::Template->new();
            $template->convert($input, $filepath);
            my $ts = time() - 30;
            $template->{timestamp} = $ts;
            $tcache->save($cachepath, $template);

            it "if cache file is not found, return undef.", sub {
                my $dummy = 'hogehoge.plhtml.cache';
                ok ! -f $dummy;
                ok ! $tcache->load($dummy, time());
            };

            it "if template timestamp is specified and different from that of cache file, return undef.", sub {
                my $ret = $tcache->load($cachepath, $ts);
                isa_ok $ret, 'HASH';
                my $ret = $tcache->load($cachepath, time());;
                ok ! $ret;
                my $ret = $tcache->load($cachepath);
                isa_ok $ret, 'HASH';
            };

            it "load template data from cache file.", sub {
                my $ret = $tcache->load($cachepath);
                isa_ok $ret, 'HASH';
                is $ret->{script}, $template->{script};
                it "get template args data from cached data.", sub {
                    is(''.@{$ret->{args}}, ''.@{$template->{args}});
                };
                is $ret->{timestamp}, $template->{timestamp};
            };

            it "return script, template args, and mtime of cache file.", sub {};

        };

    };


};
