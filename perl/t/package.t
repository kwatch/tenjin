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
use Test::More tests => 3;
use Specofit;



spec_of 'Tenjn', sub {

    it 'sets $Tenjin::USE_STRICT to 1 if strict=>1 is specified', sub {
        use Tenjin strict => 1;
        is $Tenjin::USE_STRICT, 1;
    };

    #it 'leaves $Tenjin::USE_STRICT to 0 if no option specified', sub {
    #    use Tenjin;
    #    is $Tenjin::USE_STRICT, 0;
    #};

    it "has version number", sub {
        ok defined($Tenjin::VERSION);
        like $Tenjin::VERSION, qr`^\d+\.\d+\.\d+$`;
    };

};

