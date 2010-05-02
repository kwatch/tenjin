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
use Test::More tests=>30;
use Specofit;
use File::Path;
use Tenjin;
$Tenjin::USE_STRICT = 1;


*read_file  = *Tenjin::Util::read_file;
*write_file = *Tenjin::Util::write_file;


my $TEMPLATE = <<'END';
<?pl #@ARGS $user, $get_entries ?>
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
      <?pl my $entries = $get_entries->(); ?>
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


describe "Tenjin::MemoryBaseStore", sub {
    my $store = Tenjin::MemoryBaseStore->new();
    my ($key, $value) = ("value/foo", "FOOBAR");
    spec_of "#set()", sub {
        it "saves data into memory", sub {
            $store->set($key, $value);
            should_eq($store->{values}->{$key}->[0], $value);
        };
        it "sets cache data timestamp to 0 if lifetime is not specified", sub {
            should_eq($store->{values}->{$key}->[1], 0);
        };
        it "sets cache data timestamp to lifetime seconds ahead if it is specified", sub {
            $store->set($key, $value, 10);
            should_eq($store->{values}->{$key}->[1], time() + 10);
        };
    };
    spec_of "#get()", sub {
        $store->set($key, $value, 1);
        it "returns nothing if cache data doen't exist", sub {
            should_eq($store->get('hogehogehoge'), '');
        };
        it "returns cached value if it exists", sub {
            should_eq($store->get($key), $value);
        };
        it "returns nothing if cache is expired", sub {
            sleep(2);
            should_eq($store->get($key), '');
        };
    };
    spec_of "#del()", sub {
        $store->set($key, $value);
        it "deletes value if it exists", sub {
            $store->del($key);
            should_be_false($store->{values}->{$key});
        };
        it "do nothng if value doesn't exist", sub {
            $store->del($key);
            should_be_false($store->{values}->{$key});
        };
    };
    spec_of "#has()", sub {
        $store->set($key, $value);
        it "returns 1 if value exists", sub {
            should_be_true($store->has($key))
        };
        $store->del($key);
        it "returns nothing if value doesn't exist", sub {
            should_be_false($store->has($key))
        };
    };
};


describe "Tenjin::FileBaseStore", sub {
    my $store = Tenjin::FileBaseStore->new($root_path);
    my ($key, $value, $cache_fpath) = ("value/foo", "FOOBAR", "$root_path/value/foo");
    spec_of "#set()", sub {
        it "saves data into cache file", sub {
            $store->set($key, $value);
            should_exist($cache_fpath);
        };
        it "sets cache file timestamp to 1 week ahead if lifetime is not specified", sub {
            should_eq((stat $cache_fpath)[9], time() + $Tenjin::FileBaseStore::LIFE_TIME);
        };
        it "sets cache file timestamp to lifetime seconds ahead if it is specified", sub {
            $store->set($key, $value, 10);
            should_eq((stat $cache_fpath)[9], time() + 10);
        };
    };
    spec_of "#get()", sub {
        $store->set($key, $value, 10);
        it "returns nothing if cache file doen't exist", sub {
            should_eq($store->get('hogehogehoge'), '');
        };
        it "reads cache file contents if it exists", sub {
            should_eq($store->get($key), $value);
        };
        it "returns nothing if cache file is expired", sub {
            my $now = time();
            utime($now-1, $now-1, $cache_fpath);
            should_eq($store->get($key), '');
        };
    };
    spec_of "#del()", sub {
        $store->set($key, $value);
        it "deletes cache file if it exists", sub {
            pre_cond { -f $cache_fpath };
            $store->del($key);
            should_not_exist($cache_fpath);
        };
        it "do nothng if cache file doesn't exist", sub {
            pre_cond { ! -f $cache_fpath };
            $store->del($key);
            should_not_exist($cache_fpath);
        };
    };
    spec_of "#has()", sub {
        $store->set($key, $value);
        it "returns 1 if cache file exists", sub {
            should_be_true($store->has($key))
        };
        unlink($cache_fpath);
        it "returns nothing if cache file doesn't exist", sub {
            should_be_false($store->has($key))
        };
    };
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
        my $block_called = 0;
        my $context = { user => "Haruhi",
                        get_entries => sub { $block_called = 1; $entries },
                      };
        pre_cond { ! -e $cache_path };
        my $html = $engine->render($filename, $context);
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
        my $block_called = 0;
        my $context = { user => undef,
                        get_entries => sub { $block_called = 1; $entries },
                      };
        pre_cond { -f $cache_path };
        my $html = $engine->render($filename, $context);
        should_eq($block_called, 0);
        should_eq($html, $EXPECTED2);
    };

    it "calls context block when cache is deleted", sub {
        pre_task {
            push @$entries, {title=>"Baz", content=>"<p>Bazzzz</p>"};
            $store->del($cache_key);
        };
        pre_cond { ! -e $cache_path };
        my $block_called = 0;
        my $context = { user => undef,
                        get_entries => sub { $block_called = 1; $entries },
                      };
        my $html = $engine->render($filename, $context);
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
        my $block_called = 0;
        my $context = { user => undef,
                        get_entries => sub { $block_called = 1; $entries },
                      };
        my $html = $engine->render($filename, $context);
        should_eq($block_called, 1);
        should_eq($html, $EXPECTED3);
    };

    post_task {
    };

};
