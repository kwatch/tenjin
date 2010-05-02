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
use Test::More tests=>13;
use Specofit;
use File::Path;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


my $TEMPLATE = <<'END';
<?pl #@ARGS $user, $entries ?>
<html>
  <body>
    <!-- normal part -->
    <div>
    <?pl if ($user) { ?>
      Hello [=$user=]!
      <a href="/logout">logout</a>
    <?pl } else { ?>
      <a href="/login">login</a> or
      <a href="/register">register</a>
    <?pl } ?>
    </div>
    <!-- /normal part -->
    <!-- cached part -->
    <?pl start_cache("entries/index", 10); ?>
    <dl>
      <?pl for my $entry (@$entries) { ?>
      <dt>[=$entry->{title}=]</dt>
      <dd>[==$entry->{content}=]</dd>
      <?pl } ?>
    </dl>
    <?pl stop_cache(); ?>
    <!-- /cached part -->
  </body>
</html>
END

## with {user=>"Haruhi"}
my $EXPECTED1 = <<'END';
<html>
  <body>
    <!-- normal part -->
    <div>
      Hello Haruhi!
      <a href="/logout">logout</a>
    </div>
    <!-- /normal part -->
    <!-- cached part -->
    <dl>
      <dt>Foo</dt>
      <dd><p>Fooooo</p></dd>
      <dt>Bar</dt>
      <dd><p>Baaaar</p></dd>
    </dl>
    <!-- /cached part -->
  </body>
</html>
END

## with {user=>undef}
my $EXPECTED2 = <<'END';
<html>
  <body>
    <!-- normal part -->
    <div>
      <a href="/login">login</a> or
      <a href="/register">register</a>
    </div>
    <!-- /normal part -->
    <!-- cached part -->
    <dl>
      <dt>Foo</dt>
      <dd><p>Fooooo</p></dd>
      <dt>Bar</dt>
      <dd><p>Baaaar</p></dd>
    </dl>
    <!-- /cached part -->
  </body>
</html>
END

## after new entry is added
my $EXPECTED3 = <<'END';
<html>
  <body>
    <!-- normal part -->
    <div>
      <a href="/login">login</a> or
      <a href="/register">register</a>
    </div>
    <!-- /normal part -->
    <!-- cached part -->
    <dl>
      <dt>Foo</dt>
      <dd><p>Fooooo</p></dd>
      <dt>Bar</dt>
      <dd><p>Baaaar</p></dd>
      <dt>Baz</dt>
      <dd><p>Bazzzz</p></dd>
    </dl>
    <!-- /cached part -->
  </body>
</html>
END


my $root_path = "_cache";
my $filename  = "_datacache1.plhtml";

before_all {
    mkdir $root_path unless -d $root_path;
    Tenjin::Util::write_file($filename, $TEMPLATE);
};

after_all {
    rmtree $root_path;
    unlink glob($filename.'*');
};


before_each {
};

after_each {
};


spec_of "Tenjin::Engine::render()", sub {

    my ($engine, $store, $entries, $cache_key, $cache_path);
    pre_task {
        $store = Tenjin::FileBaseStore->new($root_path);
        $engine = Tenjin::Engine->new({store=>$store});
        $entries = [ { title=>"Foo", content=>"<p>Fooooo</p>", },
                     { title=>"Bar", content=>"<p>Baaaar</p>", }, ];
        $cache_key = "entries/index";
        $cache_path = $store->filepath($cache_key);
    };

    it "calls context block when rendered at first time", sub {
        my $context = { user=>"Haruhi" };
        pre_cond { ! -e $cache_path };
        my $block_called = 0;
        my $html = $engine->render($filename, $context, sub {
            $block_called = 1;
            should_eq($_[0], $cache_key);
            { entries => $entries };
        });
        should_eq($block_called, 1);
        should_eq($html, $EXPECTED1);
        and_it "creates cache file", sub {
            ok(-f $cache_path);
            $EXPECTED1 =~ /(cached part).*?\n(.*)^.*?\/cached part/ms  or die "internal error";
            my $expected = $2;
            my $actual = Tenjin::Util::read_file($cache_path);
            should_eq($actual, $expected);
        };
    };

    it "doesn't call context block when rendered at 2nd time", sub {
        my $context = { user=>undef };
        pre_cond { -f $cache_path };
        my $block_called = 0;
        my $html = $engine->render($filename, $context, sub {
            $block_called = 1;
            should_eq($_[0], $cache_key);
            { entries => $entries };
        });
        should_eq($block_called, 0);
        should_eq($html, $EXPECTED2);
    };

    it "calls context block when cache is deleted", sub {
        pre_task {
            push @$entries, {title=>"Baz", content=>"<p>Bazzzz</p>"};
            $store->del($cache_key);
        };
        pre_cond { ! -e $cache_path };
        my $context = { user=>undef };
        my $block_called = 0;
        my $html = $engine->render($filename, $context, sub {
            $block_called = 1;
            should_eq($_[0], $cache_key);
            { entries => $entries };
        });
        should_eq($block_called, 1);
        should_eq($html, $EXPECTED3);
    };

    it "calls context block when cache is expired", sub {
        pre_task {
            my ($atime, $mtime);
            $atime = $mtime = time() - 5*60;
            utime($atime, $mtime, $cache_path);
            pre_cond { (stat $cache_path)[9] + 5*60 - 1 < time() };
        };
        my $context = { user=>undef };
        my $block_called = 0;
        my $html = $engine->render($filename, $context, sub {
            $block_called = 1;
            should_eq($_[0], $cache_key);
            { entries => $entries };
        });
        should_eq($block_called, 1);
        should_eq($html, $EXPECTED3);
    };

    post_task {
    };

};
