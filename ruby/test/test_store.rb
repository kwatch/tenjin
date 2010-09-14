###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"
require 'fileutils'


class FragmentCacheTest < Test::Unit::TestCase

  TEMPLATE = <<'END'
<html>
  <body>
    <!-- normal part -->
    <div>
    <?rb if @user ?>
      Hello ${@user}!
      <a href="/logout">logout</a>
    <?rb else ?>
      <a href="/login">login</a> or
      <a href="/register">register</a>
    <?rb end ?>
    </div>
    <!-- /normal part -->
    <!-- cached part -->
    <?rb cache_with("entries/index", 1*60) do ?>
    <dl>
      <?rb for entry in @entries ?>
      <dt>${entry[:title]}</dt>
      <dd>#{entry[:content]}</dd>
      <?rb end ?>
    </dl>
    <?rb end ?>
    <!-- /cached part -->
  </body>
</html>
END

  ## when @user == "Haruhi"
  EXPECTED1 = <<'END'
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

  ## when @user == nil
  EXPECTED2 = <<'END'
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

  ## when new entry is added
  EXPECTED3 = <<'END'
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

  def test_filebase_datacache

    root_dir = "_cache"
    filename = "_ex.rbhtml"
    begin
      FileUtils.rm_rf root_dir
      FileUtils.mkdir_p root_dir
      FileUtils.rm_f Dir.glob("#{filename}*")
      File.open(filename, "w") {|f| f.write(TEMPLATE) }
      #
      datacache = Tenjin::FileBaseStore.new(root_dir)
      cache_path = datacache.filepath("entries/index")
      engine = Tenjin::Engine.new(:datacache=>datacache)
      entries = [
        {:title=>"Foo", :content=>"<p>Fooooo</p>"},
        {:title=>"Bar", :content=>"<p>Baaaar</p>"},
      ]
      #
      if :'rendered at first time then block is called to get context data to render fragment data'
        context = {:user=>"Haruhi"}
        block_called = false
        html = engine.render(filename, context) {|cache_key|
          block_called = true
          assert_equal("entries/index", cache_key)
          case cache_key
          when "entries/index"
            {:entries => entries }
          end
        }
        assert(block_called)
        assert_text_equal(EXPECTED1, html)
        assert_file_exist(cache_path)
        expected = (EXPECTED1 =~ /(cached part).*?\n(.*)^.*?\/\1/m) && $2  or exit("internal error")
        assert_text_equal(expected, File.open(cache_path) {|f| f.read })
      end
      if :'rendered at second time then block is not called'
        context = {:user=>nil}
        block_called = false
        html = engine.render(filename, context) {|cache_key|
          block_called = true
          assert_equal("entries/index", cache_key)
          case cache_key
          when "entries/index"
            {:entries => entries }
          end
        }
        assert(! block_called)
        assert_text_equal(EXPECTED2, html)
      end
      if :'rendered after cache is cleard then block is called again'
        entries << {:title=>"Baz", :content=>"<p>Bazzzz</p>"}
        datacache.del("entries/index")
        assert_not_exist(cache_path)
        context = {:user=>nil}
        block_called = false
        html = engine.render(filename, context) {|cache_key|
          block_called = true
          assert_equal("entries/index", cache_key)
          {:entries => entries }
        }
        assert(block_called)
        assert_text_equal(EXPECTED3, html)
        expected = (EXPECTED3 =~ /(cached part).*?\n(.*)^.*?\/\1/m) && $2  or exit("internal error")
        assert_text_equal(expected, File.open(cache_path) {|f| f.read })
      end
      if :'rendered after cache is expired then block is called again'
        block_called = false
        html = engine.render(filename, context) {|cache_key|
          block_called = true
          {:entries => entries }
        }
        assert(! block_called)  # not called because cache is not expired
        ## expire cache
        atime = File.atime(cache_path)
        mtime = File.mtime(cache_path)
        File.utime(atime, mtime-5*60, cache_path)
        mtime = File.mtime(cache_path)
        ##
        block_called = false
        html = engine.render(filename, context) {|cache_key|
          block_called = true
          {:entries => entries }
        }
        assert(block_called)   # called because cache is expired
        assert(File.mtime(cache_path) > mtime+5*60-1)
      end
      if :'template file is updated then block is called again'
        ## update template timestamp
        t = Time.now + 1
        File.utime(t, t, filename)
        ##
        block_called = false
        html = engine.render(filename, context) {|cache_key|
          block_called = true
          {:entries => entries }
        }
        assert(block_called)   # called because template is updated
      end
      #
    ensure
      FileUtils.rm_rf root_dir
      FileUtils.rm_f Dir.glob("#{filename}*")
    end

  end

end
