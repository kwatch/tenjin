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


    it "has version number", sub {
        eval 'use Tenjin;';
        ! $@  or die $@;
        ok defined($Tenjin::VERSION);
        like $Tenjin::VERSION, qr`^\d+\.\d+\.\d+$`;   #`
    };


    spec_of '::import', sub {

        it "sets \$Tenjin::USE_STRICT to 1 if strict=>1 is specified", sub {
            my $bkup = $Tenjin::USE_STRICT;
            $Tenjin::USE_STRICT = undef;
            eval 'use Tenjin strict => 2;';
            ! $@  or die $@;
            is $Tenjin::USE_STRICT, 2;
            $Tenjin::USE_STRICT = $bkup;
        };

        #it "leaves \$Tenjin::USE_STRICT to 0 if no option specified", sub {
        #    use Tenjin;
        #    is $Tenjin::USE_STRICT, 0;
        #};

    };


};

