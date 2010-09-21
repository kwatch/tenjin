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
use Test::More tests => 33;
use Specofit;
use Tenjin;
$Tenjin::USE_STRICT = 1;

import Tenjin::Helper::Html;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


before_each {
};

after_each {
};


spec_of "Tenjin::Helper::Html", sub {


    spec_of "::escape_html()", sub {

        it "converts html special chars into html entity", sub {
            is escape_html('<>&"'), '&lt;&gt;&amp;&quot;';
        };

        it "doesn't convert single quote", sub {
            is escape_html("'"), "'";
        };

    };


    spec_of "::unescape_html()", sub {

        it "converts html entity to normal character", sub {
            is unescape_html('&lt;&gt;&amp;&quot;'), '<>&"';
        };

        it "converts &#039 into single quote", sub {
            is unescape_html('&#039;'), "'";
        };

    };


    spec_of "::encode_url()", sub {

        it 'encodes url string', sub {
            my $actual = encode_url('http://example.com/?xxx=1&yyy=2');
            is $actual, 'http%3A//example.com/%3Fxxx%3D1%26yyy%3D2';
        }

    };


    spec_of "::decode_url()", sub {

        it 'decodes url encoded string', sub {
            my $actual = decode_url('http%3A//example.com/%3Fxxx%3D1%26yyy%3D2');
            is $actual, 'http://example.com/?xxx=1&yyy=2';
        }

    };


    spec_of "::checked()", sub {

        it 'returns checked="checked" if argument is true', sub {
            is checked(1==1), ' checked="checked"';
        };

        it 'returns empty string if argument is false', sub {
            is checked(1==0), "";
        };

    };


    spec_of "::selected()", sub {

        it 'returns selected="selected" if argument is true', sub {
            is selected(1==1), ' selected="selected"';
        };

        it 'returns empty string if argument is false', sub {
            is selected(1==0), "";
        };

    };


    spec_of "::disabled()", sub {

        it 'returns disabled="disabled" if argument is true', sub {
            is disabled(1==1), ' disabled="disabled"';
        };

        it 'returns empty string if argument is false', sub {
            is disabled(1==0), "";
        };

    };


    spec_of "::nl2br()", sub {

        it 'converts LF into <br />', sub {
            my $str = "foo\nbar\r\nbaz";
            my $expected = "foo<br />\nbar<br />\r\nbaz";
            is nl2br($str), $expected;
        };

    };


    spec_of "::text2html()", sub {

        it 'escapes html special chars and converts LF into <br />', sub {
            my $str = "<foo>\nbar&bar\r\n\"baz\"";
            my $expected = "&lt;foo&gt;<br />\nbar&amp;bar<br />\r\n&quot;baz&quot;";
            is text2html($str), $expected;
        };

    };


    spec_of "::tagattr()", sub {

        it 'returns tag attribute string', sub {
            is tagattr('id', 123), ' id="123"';
        };

        it 'uses 3rd argument as attribute value if specified', sub {
            is tagattr('selected', 1==1, 'selected'), ' selected="selected"';
        };

        it 'returns empty string if value is false value', sub {
            is tagattr('id', 0),     '';
            is tagattr('id', ""),    '';
            is tagattr('id', undef), '';
            is tagattr('id', 0,     123), '';
            is tagattr('id', "",    123), '';
            is tagattr('id', undef, 123), '';
        };

        it "escapes html special chars in attribute value", sub {
            is tagattr('<name>', '"A&B"'), ' <name>="&quot;A&amp;B&quot;"';
        };

    };


    spec_of "::tagattrs()", sub {

        it "takes hash and returns tag attribute string", sub {
            is tagattrs(name=>"foo", id=>123), ' name="foo" id="123"';
        };

        it "doesn't skip attributes even when attributes have false-value", sub {
            is tagattrs(name=>"", id=>0), ' name="" id="0"';
        };

        it "escapes html special chars in attribute values", sub {
            is tagattrs('<name>'=>"A&B"), ' <name>="A&amp;B"';
        };

    };


    spec_of "::nv()", sub {

        it "returns name and value attributes", sub {
            my $ret = nv('pair', 'Haru&Kyon');
            is $ret, 'name="pair" value="Haru&amp;Kyon"';
        };

    };


    spec_of "::new_cycle()", sub {

        it "returns each value repeatedly", sub {
            my $cycle = new_cycle("A", "B", "C");
            is $cycle->(), "A";
            is $cycle->(), "B";
            is $cycle->(), "C";
            is $cycle->(), "A";
            is $cycle->(), "B";
            is $cycle->(), "C";
        };

    };


};
