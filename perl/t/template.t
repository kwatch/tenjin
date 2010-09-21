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
use Test::More tests => 26;
use Specofit;
use Data::Dumper;
use Tenjin strict=>1;

*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


before_each {
};

after_each {
};



my $CONTEXT1 = {
    items => ['<AAA>', 'B&B', '"CCC"'],
};


my $INPUT1 = <<'END';
	<html>
	  <body>
	    <table>
	<?pl my $i = 0; ?>
	<?pl for my $item (@$items) { ?>
	<?pl     my $color; ?>
	<?pl     if (++$i % 2 == 1) { ?>
	<?pl         $color = '#FCF'; ?>
	<?pl     } else { ?>
	<?pl         $color = '#FFF'; ?>
	<?pl     } ?>
	      <tr bgcolor="[==$color=]">
	        <td>[=$item=]</td>
	      </tr>
	<?pl } ?>
	    </table>
	  </body>
	</html>
END
$INPUT1 =~ s/^\t//mg;

my $SCRIPT1 = <<'END';
	my $_buf = ""; my $_V;  $_buf .= q`<html>
	  <body>
	    <table>
	`; my $i = 0;
	for my $item (@$items) {
	    my $color;
	    if (++$i % 2 == 1) {
	        $color = '#FCF';
	    } else {
	        $color = '#FFF';
	    }
	 $_buf .= q`      <tr bgcolor="` . ($color) . q`">
	        <td>` . (($_V = ($item)) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</td>
	      </tr>
	`; }
	 $_buf .= q`    </table>
	  </body>
	</html>
	`;  $_buf;
END
$SCRIPT1 =~ s/^\t//mg;

my $OUTPUT1 = <<'END';
	<html>
	  <body>
	    <table>
	      <tr bgcolor="#FCF">
	        <td>&lt;AAA&gt;</td>
	      </tr>
	      <tr bgcolor="#FFF">
	        <td>B&amp;B</td>
	      </tr>
	      <tr bgcolor="#FCF">
	        <td>&quot;CCC&quot;</td>
	      </tr>
	    </table>
	  </body>
	</html>
END
$OUTPUT1 =~ s/^\t//mg;


my $INPUT2 = <<'END';
	<html>
	  <body>
	    <table>
	    <?pl my $i = 0; ?>
	    <?pl for my $item (@$items) { ?>
	      <?pl my $color; ?>
	      <?pl if (++$i % 2 == 1) { ?>
	        <?pl $color = '#FCF'; ?>
	      <?pl } else { ?>
	        <?pl $color = '#FFF'; ?>
	      <?pl } ?>
	      <tr bgcolor="[==$color=]">
	        <td>[=$item=]</td>
	      </tr>
	    <?pl } ?>
	    </table>
	  </body>
	</html>
END
$INPUT2 =~ s/^\t//mg;

my $SCRIPT2 = <<'END';
	my $_buf = ""; my $_V;  $_buf .= q`<html>
	  <body>
	    <table>
	`;     my $i = 0;
	    for my $item (@$items) {
	      my $color;
	      if (++$i % 2 == 1) {
	        $color = '#FCF';
	      } else {
	        $color = '#FFF';
	      }
	 $_buf .= q`      <tr bgcolor="` . ($color) . q`">
	        <td>` . (($_V = ($item)) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</td>
	      </tr>
	`;     }
	 $_buf .= q`    </table>
	  </body>
	</html>
	`;  $_buf;
END
$SCRIPT2 =~ s/^\t//mg;


my $INPUT3 = <<'END';
	<html>
	  <body>
	    <table>
	    <?pl
	      my $i = 0;
	      for my $item (@$items) {
	        my $color;
	        if (++$i % 2 == 1) {
	          $color = '#FCF';
	        } else {
	          $color = '#FFF';
	        }
	     ?>
	      <tr bgcolor="[==$color=]">
	        <td>[=$item=]</td>
	      </tr>
	    <?pl
	      }
	     ?>
	    </table>
	  </body>
	</html>
END
$INPUT3 =~ s/^\t//mg;

my $SCRIPT3 = <<'END';
	my $_buf = ""; my $_V;  $_buf .= q`<html>
	  <body>
	    <table>
	`;     
	      my $i = 0;
	      for my $item (@$items) {
	        my $color;
	        if (++$i % 2 == 1) {
	          $color = '#FCF';
	        } else {
	          $color = '#FFF';
	        }
	    
	 $_buf .= q`      <tr bgcolor="` . ($color) . q`">
	        <td>` . (($_V = ($item)) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</td>
	      </tr>
	`;     
	      }
	    
	 $_buf .= q`    </table>
	  </body>
	</html>
	`;  $_buf;
END
$SCRIPT3 =~ s/^\t//mg;


my $INPUT9 = <<'END';
	<?pl #@ARGS $title, $items ?>
	<h1>[= $title =]</h1>
	<ul>
	<?pl for (@$items) { ?>
	  <li>[= $_ =]</li>
	<?pl } ?>
	</ul>
END
$INPUT9 =~ s/^\t//mg;


my $SCRIPT9 = <<'END';
	my $_buf = ""; my $_V; my $title = $_context->{title}; my $items = $_context->{items}; 
	 $_buf .= q`<h1>` . (($_V = ( $title )) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</h1>
	<ul>
	`; for (@$items) {
	 $_buf .= q`  <li>` . (($_V = ( $_ )) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</li>
	`; }
	 $_buf .= q`</ul>
	`;  $_buf;
END
$SCRIPT9 =~ s/^\t//mg;



spec_of "Tenjin::Template::convert()", sub {

    it "converts string into script", sub {
        my $expected = $SCRIPT1;
        my $t = Tenjin::Template->new();
        my $actual = $t->convert($INPUT1);
        should_eq($actual, $expected);
        and_it "keeps script as instance variable", sub {
            should_eq($t->{script}, $expected);
        };
    };

    it "allows embedded statements to be indented", sub {
        my $t = Tenjin::Template->new();
        my $actual = $t->convert($INPUT2);
        should_eq($actual, $SCRIPT2);
        and_it "returns script which generates the same result as not-indented input", sub {
            should_eq($t->render($CONTEXT1), $OUTPUT1);
        };
    };

    it "allows statements to be on several lines", sub {
        my $t = Tenjin::Template->new();
        my $actual = $t->convert($INPUT3);
        should_eq($actual, $SCRIPT3);
        and_it "returns script which generates the same result as not-indented input", sub {
            should_eq($t->render($CONTEXT1), $OUTPUT1);
        };
    };

    it "keeps filename if passed", sub {
        my $filename = "_foo.plhtml";
        my $t = Tenjin::Template->new();
        $t->convert($INPUT1, $filename);
        should_eq($t->{filename}, $filename);
        and_it "clears filename if not passed", sub {
            $t->convert($INPUT1);
            should_be_undef($t->{filename});
        }
    };

    it "parses \@ARGS if specified", sub {
        my $t = Tenjin::Template->new();
        should_eq($t->convert($INPUT9), $SCRIPT9);
        and_it "keeps formal parameters", sub {
            should_eq(repr($t->{args}), '["title","items"]');
        };
        and_it "doesn't compile script into closure automatically", sub {
            should_be_undef($t->{func});
        };
    };

};


spec_of "Tenjin::Template::convert_file()", sub {

    it "converts file into script", sub {
        my $filename = "_convert_file.plhtml";
        write_file($filename, $INPUT1);
        my $expected = $SCRIPT1;
        my $t = Tenjin::Template->new();
        my $actual = $t->convert_file($filename);
        unlink $filename;
        should_eq($actual, $expected);
        and_it "keeps filename as instance variable", sub {
            should_eq($t->{filename}, $filename);
        };
    };

};


spec_of "Tenjin::Template->new()", sub {

    it "returns template object", sub {
        my $t = Tenjin::Template->new();
        isa_ok $t, "Tenjin::Template";
    };

    it "converts template file if filename is specified", sub {
        my $filename = "_new_file.plhtml";
        write_file($filename, $INPUT1);
        my $t = Tenjin::Template->new($filename);
        should_eq($t->{script}, $SCRIPT1);
        should_eq($t->{filename}, $filename);
        unlink $filename if -f $filename;
    };

};


spec_of "Tenjin::Template::render()", sub {

    it "renders template with context data", sub {
        my $t = Tenjin::Template->new();
        $t->convert($INPUT1);
        my $context = { items=>['<AAA>', 'B&B', '"CCC"'] };
        my $output = $t->render($context);
        should_eq($output, $OUTPUT1);
    };

    it "reports syntax error if it exists", sub {
        my $input = <<'END';
	<ul>
	<?pl for (@_) { ?>
	  <li>[= $_ =]</li>
	<?pl } } ?>
	</ul>
END
        $input =~ s/^\t//mg;
        my $fname = '_haserr1.plhtml';
        my $expected = <<'END';
	*** ERROR: $fname
	Unmatched right curly bracket at $fname line 4, at end of line
	  (Might be a runaway multi-line `` string starting on line 3)
	syntax error at $fname line 4, near "} }"
END
        $expected =~ s/^\t//mg;
        $expected =~ s/\$fname/$fname/g;
        my $t = Tenjin::Template->new();
        $t->convert($input, $fname);
        pre_cond { ! $@ };
        eval { $t->render(); };
        should_eq($@, $expected);
    };

};


spec_of "Tenjin::Template::compile()", sub {

    it "compiles script into closure if \@ARGS is specified", sub {
        my $t = Tenjin::Template->new();
        $t->convert($INPUT9);
        is repr($t->{args}), '["title","items"]';
        ok ! $t->{func};
        my $ret = $t->compile();
        isa_ok $ret, 'CODE';
        isa_ok $t->{func}, 'CODE';
    };

    it "doesn't compile script into closure if \@ARGS is not specified", sub {
        my $t = Tenjin::Template->new();
        $t->convert($INPUT1);
        ok ! $t->{args};
        ok ! $t->compile();
        ok ! $t->{func};
    };

    it "reports error if syntax error exists", sub {
        my $input = <<'END';
	<?pl #@ARGS items ?>
	<ul>
	<?pl for (@$items) { ?>
	<?pl   $item = $_ ?>
	<?pl   my i = 0; ?>
	  <li>[= $item =]</li>
	<?pl } ?>
	</ul>
END
        $input =~ s/^\t//mg;
        my $fname = "_haserror.plhtml";
        my $expected = <<'END';
	*** Error: $fname
	Global symbol "$item" requires explicit package name at $fname line 4.
	No such class i at $fname line 5, near "$_
	  my i"
	syntax error at $fname line 5, near "$_
	  my i"
	Global symbol "$item" requires explicit package name at $fname line 6.
END
        $expected =~ s/^\t//mg;
        $expected =~ s/\$fname/$fname/g;
        my $t = Tenjin::Template->new();
        my $s = $t->convert($input, $fname);
        pre_cond { ! $@ };
        eval { $t->compile() };
        should_eq($@, $expected);
        $@ = undef;
    };

};
