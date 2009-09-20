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
use Specofit tests => 3;
use Data::Dumper;


#sub before_each {
#}
#
#sub after_each {
#}


spec_of 'Tenjn', sub {

    it 'sets $Tenjin::USE_STRICT to 1 if strict=>1 is specified', sub {
        use Tenjin strict => 1;
        should_eq($Tenjin::USE_STRICT, 1);
    };

    #it 'leaves $Tenjin::USE_STRICT to 0 if no option specified', sub {
    #    use Tenjin;
    #    should_eq($Tenjin::USE_STRICT, 0);
    #};

    it "has version number", sub {
        should_be_true(defined($Tenjin::VERSION));
        should_match($Tenjin::VERSION, '^\d+\.\d+\.\d+$');
    };

};

