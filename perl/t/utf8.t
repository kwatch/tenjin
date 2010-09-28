# -*- coding: utf-8 -*-
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
use Test::More tests => 1;
use Specofit;
use Tenjin;
$Tenjin::USE_STRICT = 1;

use utf8;    # !!!!


sub _remove_file {
    my ($fname, $block) = @_;
    eval { $block->(); };
    unlink($fname) if -f $fname;
    die $@ if $@;
}


spec_of "Tenjin::Engine", sub {


    spec "handles non-ascii template files and context data", sub {
        my $input = <<'END';
<?pl # -*- coding: utf-8 -*- ?>
<body>
  <h1>SOS団ホームページ</h1>
  <h1>[= $title =]</h1>
  <h1>[== $title =]</h1>
</body>
END
        my $expected = <<'END';
<body>
  <h1>SOS団ホームページ</h1>
  <h1>SOS団ホームページ</h1>
  <h1>SOS団ホームページ</h1>
</body>
END
        my $fname = "_test_utf8.plhtml";
        pre_task {
            open my $fh, '>', $fname  or die "$fname: $!";
            utf8::encode($input);
            print $fh $input;
            close $fh;
        };
        #
        my $context = { title => 'SOS団ホームページ' };
        my $engine = Tenjin::Engine->new();
        my $output = $engine->render($fname, $context);
        is $output, $expected;
        post_task {
            unlink $_ for glob("$fname*");
        };
    };


};
