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
use Test::Simple tests => 12;
use Specofit;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


spec_of "Tenjin::SafeStr->new", sub {

    it "returns Tenjin::SafeStr object", sub {
        my $obj = Tenjin::SafeStr->new('<A&B>');
        should_eq(ref($obj), "Tenjin::SafeStr");
        should_eq(repr($obj), q|bless( {"value" => "<A&B>"}, 'Tenjin::SafeStr' )|);
    };

};


spec_of "Tenjin::SafeStr#to_str", sub {

    it "returns safe string", sub {
        my $obj = Tenjin::SafeStr->new('<A&B>');
        should_eq($obj->to_str, '<A&B>');
    };

};


spec_of "Tenjin::SafeTemplate#convert", sub {

    it "generates script to check whether value is safe string or not", sub {
        my $t = Tenjin::SafeTemplate->new(undef);
        my $input = "<div>\n[= \$_content =]\n</div>\n";
        my $expected = <<'END';
	my $_buf = ""; my $_V;  $_buf .= q`<div>
	` . (ref($_V = ( $_content )) eq 'Tenjin::SafeStr' ? $_V->{value} : ($_V =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V)) . q`
	</div>
	`;  $_buf;
END
        $expected =~ s/^\t//mg;
        should_eq($t->convert($input), $expected);
    };

    it "refuses to compile '[== expr =]'", sub {
        my $t = Tenjin::SafeTemplate->new(undef);
        my $input = "<div>\n[== \$_content =]\n</div>\n";
        eval { $t->convert($input); };
        $_ = $@;
        s/ at .*$//;
        should_eq($_, "'[== \$_content =]': '[== =]' is not available with Tenjin::SafeTemplate.\n");
    };

};


spec_of "Tenjin::SafeTemplate#render", sub {

    it "doesn't escape safe string value", sub {
        my $t = Tenjin::SafeTemplate->new(undef);
        my $input = "<div>\n[= \$_content =]\n</div>\n";
        $t->convert($input);
        my $actual = $t->render({_content => '<AAA&BBB>'});
        should_eq($actual, "<div>\n&lt;AAA&amp;BBB&gt;\n</div>\n");
        my $actual = $t->render({_content => Tenjin::SafeStr->new('<AAA&BBB>')});
        should_eq($actual, "<div>\n<AAA&BBB>\n</div>\n");
    };

};


spec_of "Tenjin::SafePreprocessor#convert", sub {

    it "generates script to check whether value is safe string or not", sub {
        my $pp = Tenjin::SafePreprocessor->new();
        my $ret = $pp->convert('<<[*=$x=*]>>');
        should_eq($ret, 'my $_buf = ""; my $_V;  $_buf .= q`<<` . (ref($_V = ($x)) eq \'Tenjin::SafeStr\' ? Tenjin::Util::_decode_params($_V->{value}) : ($_V = Tenjin::Util::_decode_params($_V), $_V =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V)) . q`>>`;  $_buf;'."\n");
    };

    it "refuses to compile '[== expr =]'", sub {
        my $pp = Tenjin::SafePreprocessor->new();
        eval { $pp->convert('<<[*==$x=*]>>'); };
        $_ = $@;
        s/ at .*$//;
        should_eq($_, "'[*==\$x=*]': '[*== =*]' is not available with Tenjin::SafePreprocessor."."\n");
        $@ = '';
    };

};


spec_of "Tenjin::SafeEngine", sub {

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
 $_buf .= q`  <li>` . (ref($_V = ( $_ )) eq 'Tenjin::SafeStr' ? $_V->{value} : ($_V =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V)) . q`</li>
`;   }
 $_buf .= q`</ul>
`;  $_buf;
END

    my $CONTEXT = {
        items => [ "<br>", Tenjin::SafeStr->new("<BR>") ],
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
        it "passes 'safeclass' option to template class", sub {
            $engine = Tenjin::SafeEngine->new();
            my $t = $engine->get_template("_ex.plhtml");
            should_eq(ref($t), 'Tenjin::SafeTemplate');
            should_eq($t->{script}, $SCRIPT);
        };
    };

    spec_of "#render", sub {
        it "prints safe string as it is", sub {
            my $output = $engine->render("_ex.plhtml", $CONTEXT);
            should_eq($output, $EXPECTED);
        };
    };

    post_task {
        unlink glob("_ex.plhtml*");
    };

};
