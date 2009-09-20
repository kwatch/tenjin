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
use Specofit tests => 32;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


sub before_each {
}

sub after_each {
}


spec_of "Tenjin::Helper::Html::escape_xml()", sub {

    it "converts html special chars into html entity", sub {
        should_eq(Tenjin::Helper::Html::escape_xml('<>&"'), '&lt;&gt;&amp;&quot;');
    };

    it "doesn't convert single quote", sub {
        should_eq(Tenjin::Helper::Html::escape_xml("'"), "'");
    };

};


spec_of "Tenjin::Helper::Html::unescape_xml()", sub {

    it "converts html entity to normal character", sub {
        should_eq(Tenjin::Helper::Html::unescape_xml('&lt;&gt;&amp;&quot;'), '<>&"');
    };

    it "converts &#039 into single quote", sub {
        should_eq(Tenjin::Helper::Html::unescape_xml('&#039;'), "'");
    };

};


spec_of "Tenjin::Helper::Html::encode_url()", sub {

    it 'encodes url string', sub {
        my $actual = Tenjin::Helper::Html::encode_url('http://example.com/?xxx=1&yyy=2');
        should_eq($actual, 'http%3A//example.com/%3Fxxx%3D1%26yyy%3D2');
    }

};


spec_of "Tenjin::Helper::Html::decode_url()", sub {

    it 'decodes url encoded string', sub {
        my $actual = Tenjin::Helper::Html::decode_url('http%3A//example.com/%3Fxxx%3D1%26yyy%3D2');
        should_eq($actual, 'http://example.com/?xxx=1&yyy=2');
    }

};


spec_of "Tenjin::Helper::Html::checked()", sub {

    it 'returns checked="checked" if argument is true', sub {
        should_eq(Tenjin::Helper::Html::checked(1==1), ' checked="checked"');
    };

    it 'returns empty string if argument is false', sub {
        should_eq(Tenjin::Helper::Html::checked(1==0), "");
        #should_be_undef(Tenjin::Helper::Html::checked(1==0));
    };

};


spec_of "Tenjin::Helper::Html::selected()", sub {

    it 'returns selected="selected" if argument is true', sub {
        should_eq(Tenjin::Helper::Html::selected(1==1), ' selected="selected"');
    };

    it 'returns empty string if argument is false', sub {
        should_eq(Tenjin::Helper::Html::selected(1==0), "");
        #should_be_undef(Tenjin::Helper::Html::selected(1==0));
    };

};


spec_of "Tenjin::Helper::Html::disabled()", sub {

    it 'returns disabled="disabled" if argument is true', sub {
        should_eq(Tenjin::Helper::Html::disabled(1==1), ' disabled="disabled"');
    };

    it 'returns empty string if argument is false', sub {
        should_eq(Tenjin::Helper::Html::disabled(1==0), "");
        #should_be_undef(Tenjin::Helper::Html::disabled(1==0));
    };

};


spec_of "Tenjin::Helper::Html::nl2br()", sub {

    it 'converts LF into <br />', sub {
        my $str = "foo\nbar\r\nbaz";
        my $expected = "foo<br />\nbar<br />\r\nbaz";
        should_eq(Tenjin::Helper::Html::nl2br($str), $expected);
    };

};


spec_of "Tenjin::Helper::Html::text2html()", sub {

    it 'escapes html special chars and converts LF into <br />', sub {
        my $str = "<foo>\nbar&bar\r\n\"baz\"";
        my $expected = "&lt;foo&gt;<br />\nbar&amp;bar<br />\r\n&quot;baz&quot;";
        should_eq(Tenjin::Helper::Html::text2html($str), $expected);
    };

};


spec_of "Tenjin::Helper::Html::tagattr()", sub {

    it 'returns tag attribute string', sub {
        should_eq(Tenjin::Helper::Html::tagattr('id', 123), ' id="123"');
    };

    it 'uses 3rd argument as attribute value if specified', sub {
        should_eq(Tenjin::Helper::Html::tagattr('selected', 1==1, 'selected'), ' selected="selected"');
    };

    it 'returns empty string if value is false value', sub {
        should_eq(Tenjin::Helper::Html::tagattr('id', 0),     '');
        should_eq(Tenjin::Helper::Html::tagattr('id', ""),    '');
        should_eq(Tenjin::Helper::Html::tagattr('id', undef), '');
        should_eq(Tenjin::Helper::Html::tagattr('id', 0,     123), '');
        should_eq(Tenjin::Helper::Html::tagattr('id', "",    123), '');
        should_eq(Tenjin::Helper::Html::tagattr('id', undef, 123), '');
    };

    it "escapes html special chars in attribute value", sub {
        should_eq(Tenjin::Helper::Html::tagattr('<name>', '"A&B"'), ' <name>="&quot;A&amp;B&quot;"');
    };

};


spec_of "Tenjin::Helper::Html::tagattrs()", sub {

    it "takes hash and returns tag attribute string", sub {
        should_eq(Tenjin::Helper::Html::tagattrs(name=>"foo", id=>123), ' name="foo" id="123"');
    };

    it "doesn't skip attributes even when attributes have false-value", sub {
        should_eq(Tenjin::Helper::Html::tagattrs(name=>"", id=>0), ' name="" id="0"');
    };

    it "escapes html special chars in attribute values", sub {
        should_eq(Tenjin::Helper::Html::tagattrs('<name>'=>"A&B"), ' <name>="A&amp;B"');
    };

};


spec_of "Tenjin::Helper::Html::new_cycle()", sub {

    it "returns each value repeatedly", sub {
        my $cycle = Tenjin::Helper::Html::new_cycle("A", "B", "C");
        should_eq($cycle->(), "A");
        should_eq($cycle->(), "B");
        should_eq($cycle->(), "C");
        should_eq($cycle->(), "A");
        should_eq($cycle->(), "B");
        should_eq($cycle->(), "C");
    };

};
