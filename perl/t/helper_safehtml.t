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
use Test::More;
use Specofit tests => 52;
use Tenjin;
$Tenjin::USE_STRICT = 1;
import Tenjin::Helper::SafeHtml;


*safe_str   = *Tenjin::Helper::SafeHtml::safe_str;


before_each {
};

after_each {
};


spec_of "Tenjin::Helper::SafeHtml::checked()", sub {

    it "returns SafeStr object, even if arg is false", sub {
        isa_ok checked(1), 'Tenjin::SafeStr';
        is checked(1)->{value}, ' checked="checked"';
        isa_ok checked(0), 'Tenjin::SafeStr';
        is checked(0)->{value}, '';
    };

};


spec_of "Tenjin::Helper::SafeHtml::selected()", sub {

    it "returns SafeStr object, even if arg is false", sub {
        isa_ok selected(1), 'Tenjin::SafeStr';
        is selected(1)->{value}, ' selected="selected"';
        isa_ok selected(!1), 'Tenjin::SafeStr';
        is selected(!1)->{value}, '';
    };

};


spec_of "Tenjin::Helper::SafeHtml::disabled()", sub {

    it "returns SafeStr object, even if arg is false", sub {
        isa_ok disabled(1), 'Tenjin::SafeStr';
        is disabled(1)->{value}, ' disabled="disabled"';
        isa_ok disabled(!1), 'Tenjin::SafeStr';
        is disabled(!1)->{value}, '';
    };

};


spec_of "Tenjin::Helper::SafeHtml::nl2br()", sub {

    it "returns SafeStr object, even if arg is false", sub {
        my $ss = "<p>\n</p>\n";
        isa_ok nl2br($ss), 'Tenjin::SafeStr';
        is nl2br($ss)->{value}, "<p><br />\n</p><br />\n";
        isa_ok nl2br(''), 'Tenjin::SafeStr';
        is nl2br('')->{value}, '';
    };

    it "accepts SafeStr object", sub {
        my $ss = safe_str("<p>\n</p>\n");
        isa_ok nl2br($ss), 'Tenjin::SafeStr';
        is nl2br($ss)->{value}, "<p><br />\n</p><br />\n";
    };

};


spec_of "Tenjin::Helper::SafeHtml::text2html()", sub {

    it "returns SafeStr object, even if arg is false", sub {
        my $ss = "<p>\n</p>\n";
        isa_ok text2html($ss), 'Tenjin::SafeStr';
        is text2html($ss)->{value}, "&lt;p&gt;<br />\n&lt;/p&gt;<br />\n";
        isa_ok text2html(''), 'Tenjin::SafeStr';
        is text2html('')->{value}, '';
    };

    it "accepts SafeStr object", sub {
        my $ss = safe_str("<p>\n</p>\n");
        isa_ok text2html($ss), 'Tenjin::SafeStr';
        is text2html($ss)->{value}, "<p><br />\n</p><br />\n";
    };

};


spec_of "Tenjin::Helper::SafeHtml::tagattr()", sub {

    it "returns SafeStr object, even if arg is false", sub {
        my $ret = tagattr('title', '"AAA"');
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, ' title="&quot;AAA&quot;"';
        my $ret = tagattr('title', undef);
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, '';
    };

    it "accepts SafeStr object", sub {
        my $ret = tagattr('title', safe_str('"AAA"'));
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, ' title=""AAA""';
    };

};


spec_of "Tenjin::Helper::SafeHtml::tagattrs()", sub {

    it "returns SafeStr object, even if arg is false", sub {
        my $ret = tagattrs(a=>'"A"', b=>'"B"');
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, ' a="&quot;A&quot;" b="&quot;B&quot;"';
        my $ret = tagattrs('title', undef);
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, '';
    };

    it "accepts SafeStr object", sub {
        my $ret = tagattrs(a=>safe_str('"A"'), b=>'"B"');
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, ' a=""A"" b="&quot;B&quot;"';
    };

};


spec_of "Tenjin::Helper::SafeHtml::new_cycle()", sub {

    it "returns SafeStr object, even if arg is false", sub {
        my $cycle = new_cycle('A&A', 'B&B');
        my $ret = $cycle->();
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, 'A&amp;A';
        my $ret = $cycle->();
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, 'B&amp;B';
    };

    it "accepts SafeStr object", sub {
        my $cycle = new_cycle(safe_str('A&A'), 'B&B');
        my $ret = $cycle->();
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, 'A&A';
        my $ret = $cycle->();
        isa_ok $ret, 'Tenjin::SafeStr';
        is $ret->{value}, 'B&amp;B';
    };

};


spec_of "Tenjin::Helper::SafeHtml::import()", sub {

    it "sets safe html helpers to Context class", sub {
        my $ret = Tenjin::Context::checked(1);
        isa_ok Tenjin::Context::checked(1), 'Tenjin::SafeStr';
        isa_ok Tenjin::Context::selected(1), 'Tenjin::SafeStr';
        isa_ok Tenjin::Context::disabled(1), 'Tenjin::SafeStr';
        isa_ok Tenjin::Context::nl2br("\n"), 'Tenjin::SafeStr';
        isa_ok Tenjin::Context::text2html("<p>"), 'Tenjin::SafeStr';
        isa_ok Tenjin::Context::tagattr('a', 'A'), 'Tenjin::SafeStr';
        isa_ok Tenjin::Context::tagattrs(a=>'A'), 'Tenjin::SafeStr';
        isa_ok Tenjin::Context::new_cycle('A')->(), 'Tenjin::SafeStr';
    };

};
