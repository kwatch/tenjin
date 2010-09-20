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
use File::Path;    # mkpath(), rmtree()
use Data::Dumper;
use Test::Simple tests => 11;
use Specofit;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


sub _with_dummies (&) {
    my ($block) = @_;
    ##
    mkpath('_views/blog');
    write_file('_views/blog/index.plhtml', 'AAA');
    write_file('_views/index.plhtml', 'BBB');
    write_file('_views/layout.plhtml', '<<[==$_content=]>>');
    ##
    eval {
        my $finder = Tenjin::FileFinder->new();
        $block->($finder);
    };
    ##
    rmtree('_views');
    ##
    die $@ if $@;
}


spec_of "Tenjin::FileFinder->find", sub {

    my $dirs = ['_views/blog', '_views'];

    it "searches filename in dirs if dirs passed", sub {
        _with_dummies {
            my ($finder) = @_;
            my $fpath = $finder->find('index.plhtml', $dirs);
            should_eq($fpath, '_views/blog/index.plhtml');
            my $fpath = $finder->find('layout.plhtml', $dirs);
            should_eq($fpath, '_views/layout.plhtml');
        };
    };

    it "returns filename if it exists and dirs not passed", sub {
        _with_dummies {
            my ($finder) = @_;
            my $fpath = $finder->find('_views/index.plhtml');
            should_eq($fpath, '_views/index.plhtml');
        };
    };

    it "returns nothing if file is not found", sub {
        _with_dummies {
            my ($finder) = @_;
            should_eq($finder->find('index2.pltml', $dirs), undef);
            should_eq($finder->find('_views/index2.pltml'), undef);
        };
    };

};


spec_of "Tenjin::FileFinder->timestamp", sub {

    it "returns mtime of file", sub {
        _with_dummies {
            my ($finder) = @_;
            my $fname = '_views/blog/index.plhtml';
            my $ts = time() - 30;
            utime($ts, $ts, $fname);
            should_eq($finder->timestamp($fname), $ts);
        };
    };

    it "returns undef if file not found", sub {
        _with_dummies {
            my ($finder) = @_;
            should_eq($finder->timestamp('_views/index2.plhtml'), undef);
        };
    };

};


spec_of "Tenjin::FileFinder->read", sub {

    it "returns file content and mtime if file exists", sub {
        _with_dummies {
            my ($finder) = @_;
            my $fname = '_views/blog/index.plhtml';
            my $ts = time() - 30;
            utime($ts, $ts, $fname);
            my ($input, $mtime) = $finder->read($fname);
            should_eq($input, 'AAA');
            should_eq($mtime, $ts);
        };
    };

    it "return undef if file not exist", sub {
        _with_dummies {
            my ($finder) = @_;
            my ($input, $mtime) = $finder->read('_views/index2.html');
            should_eq($input, undef);
            should_eq($mtime, undef);
        }
    }

};
