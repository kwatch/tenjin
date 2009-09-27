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
use Test::Simple tests => 9;
use Specofit;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


spec_of "Tenjin::RawString->new", sub {

    it "returns Tenjin::RawString object", sub {
        my $obj = Tenjin::RawString->new('<A&B>');
        should_eq(ref($obj), "Tenjin::RawString");
        should_eq(repr($obj), q|bless( {"str" => "<A&B>"}, 'Tenjin::RawString' )|);
    };

};


spec_of "Tenjin::RawString#to_str", sub {

    it "returns raw string", sub {
        my $obj = Tenjin::RawString->new('<A&B>');
        should_eq($obj->to_str, '<A&B>');
    };

};


spec_of "Tenjin::Template#convert", sub {

    it "generates script to check whether value is raw string or not", sub {
        my $t = Tenjin::Template->new(undef, {rawclass=>'Tenjin::RawString'});
        my $input = "<div>\n[= \$_content =]\n</div>\n";
        my $expected = <<'END';
	my $_buf = ""; my $_V;  $_buf .= q`<div>
	` . (ref($_V = ( $_content )) eq 'Tenjin::RawString' ? $_V->{str} : ($_V =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V)) . q`
	</div>
	`;  $_buf;
END
        $expected =~ s/^\t//mg;
        should_eq($t->convert($input), $expected);
    };

};


spec_of "Tenjin::Template#render", sub {

    it "doesn't escape raw string value", sub {
        my $t = Tenjin::Template->new(undef, {rawclass=>'Tenjin::RawString'});
        my $input = "<div>\n[= \$_content =]\n</div>\n";
        $t->convert($input);
        my $actual = $t->render({_content => '<AAA&BBB>'});
        should_eq($actual, "<div>\n&lt;AAA&amp;BBB&gt;\n</div>\n");
        my $actual = $t->render({_content => Tenjin::RawString->new('<AAA&BBB>')});
        should_eq($actual, "<div>\n<AAA&BBB>\n</div>\n");
    };

};


spec_of "Tenjin::Engine", sub {

    my $INPUT = <<'END';
	<ul>
	  <?pl for (@$items) { ?>
	  <li>[= $_ =]</li>
	  <?pl } ?>
	</ul>
END
    $INPUT =~ s/^\t//mg;

    my $SCRIPT = <<'END';
my $_buf = ""; my $_V;  $_buf .= q`<ul>
`;   for (@$items) {
 $_buf .= q`  <li>` . (ref($_V = ( $_ )) eq 'Tenjin::RawString' ? $_V->{str} : ($_V =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V)) . q`</li>
`;   }
 $_buf .= q`</ul>
`;  $_buf;
END

    my $CONTEXT = {
        items => [ "<br>", Tenjin::RawString->new("<BR>") ],
    };

    my $EXPECTED = <<'END';
	<ul>
	  <li>&lt;br&gt;</li>
	  <li><BR></li>
	</ul>
END
    $EXPECTED =~ s/^\t//mg;

    pre_task {
        unlink glob("_ex.plhtml*");
        write_file("_ex.plhtml", $INPUT);
    };

    my $engine;

    spec_of "->new", sub {
        it "passes 'rawclass' option to template class", sub {
            $engine = Tenjin::Engine->new({rawclass=>'Tenjin::RawString'});
            my $t = $engine->get_template("_ex.plhtml");
            should_eq($t->{rawclass}, 'Tenjin::RawString');
            should_eq($t->{script}, $SCRIPT);
        };
    };

    spec_of "#render", sub {
        it "prints raw string as it is", sub {
            my $output = $engine->render("_ex.plhtml", $CONTEXT);
            should_eq($output, $EXPECTED);
        };
    };

    post_task {
        unlink glob("_ex.plhtml*");
    };

};
