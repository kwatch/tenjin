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
use Test::Simple tests => 21;
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

    it "converts Tenjin::SafeStr to normal string", sub {
        my $obj = Tenjin::SafeStr->new('<A&B>');
        should_eq($obj->to_str, '<A&B>');
    };

};


spec_of "Tenjin::SafeStr::safe_str", sub {

    it "returns Tenjin::SafeStr object", sub {
        my $obj = Tenjin::SafeStr::safe_str('<A&B>');
        should_eq(ref($obj), 'Tenjin::SafeStr');
    };

};


spec_of "Tenjin::SafeStr::is_safe_str", sub {

    it "returns 1 if arg is Tenjin::SafeStr object", sub {
        my $obj = Tenjin::SafeStr::safe_str('<A&B>');
        should_eq(Tenjin::SafeStr::is_safe_str($obj), 1);
    };

    it "returns undef if arg is not Tenjin::SafeStr object", sub {
        should_eq(Tenjin::SafeStr::is_safe_str('<A&B>'), undef);
    };

};


spec_of "Tenjin::SafeStr::safe_escape", sub {

    it "returns unescaped str if arg is Tenjin::SafeStr", sub {
        my $obj = Tenjin::SafeStr::safe_str('<A&B>');
        should_eq(Tenjin::SafeStr::safe_escape($obj), '<A&B>');
    };

    it "returns escaped str if arg is normal string", sub {
        should_eq(Tenjin::SafeStr::safe_escape('<A&B>'), '&lt;A&amp;B&gt;');
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
    $SCRIPT =~ s/^\t//mg;

    my $EXPECTED = <<'END';
	<ul>
	  <li>&lt;br&gt;</li>
	  <li><BR></li>
	</ul>
END
    $EXPECTED =~ s/^\t//mg;

    my $INPUT2 = <<'END';
	<div>
	  <p>v1=[=$v1=]</p>
	  <p>v2=[=$v2=]</p>
	</div>
	<div>
	  <p>v1=[*=$v1=*]</p>
	  <p>v2=[*=$v2=*]</p>
	</div>
END
    $INPUT2 =~ s/^\t//mg;

    my $SCRIPT2 = <<'END';
	my $_buf = ""; my $_V;  $_buf .= q`<div>
	  <p>v1=` . (ref($_V = ($v1)) eq 'Tenjin::SafeStr' ? $_V->{value} : ($_V =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V)) . q`</p>
	  <p>v2=` . (ref($_V = ($v2)) eq 'Tenjin::SafeStr' ? $_V->{value} : ($_V =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V)) . q`</p>
	</div>
	<div>
	  <p>v1=&lt;&amp;&gt;</p>
	  <p>v2=<&></p>
	</div>
	`;  $_buf;
END
    $SCRIPT2 =~ s/^\t//mg;

    my $EXPECTED2 = <<'END';
	<div>
	  <p>v1=&lt;&amp;&gt;</p>
	  <p>v2=<&></p>
	</div>
	<div>
	  <p>v1=&lt;&amp;&gt;</p>
	  <p>v2=<&></p>
	</div>
END
    $EXPECTED2 =~ s/^\t//mg;

    my $CONTEXT = {
        items => [ "<br>", Tenjin::SafeStr->new("<BR>") ],
    };

    pre_task {
        unlink glob("_ex.plhtml*");
        write_file("_ex.plhtml", $INPUT);
        unlink glob("_ex2.plhtml*");
        write_file("_ex2.plhtml", $INPUT2);
    };

    my $engine;

    spec_of "->new", sub {
        my $engine = Tenjin::SafeEngine->new();
        it "sets 'templateclass' attribute to 'SafeTemplate'", sub {
            should_eq($engine->{templateclass}, 'Tenjin::SafeTemplate');
            my $t = $engine->get_template("_ex.plhtml");
            should_eq(ref($t), 'Tenjin::SafeTemplate');
            should_eq($t->{script}, $SCRIPT);
        };
        it "sets 'preprocessor' attribute to 'SafePreprocessor'", sub {
            should_eq($engine->{preprocessorclass}, 'Tenjin::SafePreprocessor');
        }
    };

    spec_of "#render", sub {
        it "prints safe string as it is", sub {
            my $e = Tenjin::SafeEngine->new();
            my $output = $e->render("_ex.plhtml", $CONTEXT);
            should_eq($output, $EXPECTED);
        };
        it "supports preprocessing with SafePreprocessor class", sub {
            my $e = Tenjin::SafeEngine->new({preprocess=>1});
            my $context = { v1=>'<&>', v2=>Tenjin::SafeStr->new('<&>') };
            my $output = $e->render("_ex2.plhtml", $context);
            my $t = $e->get_template('_ex2.plhtml');
            should_eq($t->{script}, $SCRIPT2);
            should_eq($output, $EXPECTED2);
        };
    };

    post_task {
        unlink glob("_ex.plhtml*");
        unlink glob("_ex2.plhtml*");
    };

};
