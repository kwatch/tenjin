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
use Test::Simple tests => 10;
use Specofit;
use Tenjin;
$Tenjin::USE_STRICT = 1;

import Tenjin::Helper::Safe;


spec_of "Tenjin::Helper::Safe::safe_str", sub {

    it "returns Tenjin::SafeStr object", sub {
        my $obj = safe_str('<A&B>');
        should_eq(ref($obj), 'Tenjin::SafeStr');
    };

};


spec_of "Tenjin::Helper::Safe::to_safe_str", sub {

    it "returns Tenjin::SafeStr object if arg is normal string", sub {
        my $obj = to_safe_str('<A&B>');
        should_eq(ref($obj), 'Tenjin::SafeStr');
    };

    it "returns as-is arg if arg is Tenjin::SafeStr object", sub {
        my $obj = to_safe_str('<A&B>');
        my $obj2 = to_safe_str($obj);
        should_eq(ref($obj2), 'Tenjin::SafeStr');
        should_eq($obj2->{value}, '<A&B>');
    };

};


spec_of "Tenjin::Helper::Safe::to_str", sub {

    it "returns value-string if arg is Tenjin::SafeStr object", sub {
        my $obj = safe_str('<A&B>');
        should_eq(to_str($obj), '<A&B>');
    };

    it "returns as-is arg if arg is a string", sub {
        should_eq(to_str('<A&B>'), '<A&B>');
    };

};


spec_of "Tenjin::Helper::Safe::is_safe_str", sub {

    it "returns 1 if arg is Tenjin::SafeStr object", sub {
        my $obj = safe_str('<A&B>');
        should_eq(is_safe_str($obj), 1);
    };

    it "returns undef if arg is not Tenjin::SafeStr object", sub {
        should_eq(is_safe_str('<A&B>'), undef);
    };

};


spec_of "Tenjin::Helper::Safe::safe_escape", sub {

    it "returns unescaped str if arg is Tenjin::SafeStr", sub {
        my $obj = safe_str('<A&B>');
        should_eq(safe_escape($obj), '<A&B>');
    };

    it "returns escaped str if arg is normal string", sub {
        should_eq(safe_escape('<A&B>'), '&lt;A&amp;B&gt;');
    };

};
