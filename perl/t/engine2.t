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
use Data::Dumper tests => 10;
use Specofit;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;

my $FILENAME = '_example.plhtml';


my $CONTEXT1 = {
    title => 'Tom&Jerry',
    items => ['<AAA>', 'B&B', '"CCC"'],
};


my $INPUT1 = <<'END';
	<html>
	<?pl #@ARGS title, items ?>
	  <body>
	    <h1>[=$title=]</h1>
	    <table>
	      <?pl my $i = 0; ?>
	      <?pl for my $item (@$items) { ?>
	      <?pl   my $color = ++$i % 2 ? '#FCF' : '#FFF'; ?>
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
	`; my $title = $_context->{title}; my $items = $_context->{items}; 
	 $_buf .= q`  <body>
	    <h1>` . (($_V = ($title)) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</h1>
	    <table>
	`;       my $i = 0;
	      for my $item (@$items) {
	        my $color = ++$i % 2 ? '#FCF' : '#FFF';
	 $_buf .= q`      <tr bgcolor="` . ($color) . q`">
	        <td>` . (($_V = ($item)) =~ s/[&<>"]/$Tenjin::_H{$&}/ge, $_V) . q`</td>
	      </tr>
	`;       }
	 $_buf .= q`    </table>
	  </body>
	</html>
	`;  $_buf;
END
$SCRIPT1 =~ s/^\t//mg;


my $CACHE1 = "#\@ARGS title,items\n" . $SCRIPT1;


my $OUTPUT1 = <<'END';
	<html>
	  <body>
	    <h1>Tom&amp;Jerry</h1>
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


my $INPUT9 = <<'END';
	<?pl #@ARGS title, items ?>
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
	 $_buf .= q`  <li>` . escape( $_ ) . q`</li>
	`; }
	 $_buf .= q`</ul>
	`;  $_buf;
END
$SCRIPT9 =~ s/^\t//mg;



before_each {
    for (glob($FILENAME.'*')) { unlink $_; }
    write_file($FILENAME, $INPUT1);
};

after_each {
    unlink $FILENAME if -f $FILENAME;
};



spec_of "Tenjin::Engine::render()", sub {

    it "returns rendered output", sub {
        my $e = Tenjin::Engine->new();
        my $output = $e->render("$FILENAME", $CONTEXT1);
        should_eq($output, $OUTPUT1);
    };

    it "creates cache file automatically if it doen't exist", sub {
        pre_cond { ! -f "$FILENAME.cache" };   # cache file doesn't exist
        my $e = Tenjin::Engine->new();
        my $output = $e->render("$FILENAME", $CONTEXT1);
        should_be_true(-f "$FILENAME.cache");
        and_it "loads #\@ARGS from template", sub {
            my $t = $e->get_template("$FILENAME");
            should_eq(repr($t->{args}), '["title","items"]');
        };
        and_it "stores #\@ARGS into cache file", sub {
            my $expected = "#\@ARGS title,items\n" . $SCRIPT1;
            should_eq(read_file("$FILENAME.cache"), $expected);
        };
        and_it "compiles template automatically", sub {
            my $t = $e->get_template("$FILENAME");
            should_eq(ref($t->{func}), "CODE");
        };
    };

    it "loads cache file if it exists", sub {
        my $dummy_content = "<!-- -->";
        pre_task {
            write_file("$FILENAME", $dummy_content);   # change template content
            write_file("$FILENAME.cache", $CACHE1);
        };
        pre_cond { -f "$FILENAME.cache" };
        my $e = Tenjin::Engine->new();
        my $output = $e->render("$FILENAME", $CONTEXT1);
        should_eq($output, $OUTPUT1);       # not dummy data
        my $t = $e->get_template("$FILENAME");
        should_eq($t->{script}, $SCRIPT1);  # not dummy data
        and_it "loads #\@ARGS from cache file", sub {
            should_eq(repr($t->{args}), '["title","items"]');
        };
        and_it "compiles template automatically", sub {
            should_eq(ref($t->{func}), "CODE");
        };
    };

    it "reports error if template file doesn't exist", sub {
        my $fname = "_foobar.plhtml";
        pre_cond { ! -f $fname };
        my $e = Tenjin::Engine->new();
        eval { $e->render($fname, $CONTEXT1); };
        should_match($@, '^_foobar.plhtml: template not found.');
    };

};

