###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"


class TemplateCacheTest
  include Oktest::TestCase

  def test_cachename
    cache = Tenjin::TemplateCache.new()
    fpath = 'foobar.rbhtml'.taint
    ok_(fpath.tainted?) == true
    ret = cache.cachename(fpath)
    ok_(ret) == fpath + '.cache'
    ok_(ret.tainted?) == false
  end
end


class FileBaseTemplateCacheTest
  include Oktest::TestCase

  def before
    @klass = Tenjin::FileBaseTemplateCache
    @cache = @klass.new
    @filepath = "_test_example.rbhtml"
    @input = <<'END'
<?rb #@ARGS name,  items ?>
<p>Hello ${@name}!</p>
<?rb for item in @items ?>
<p>${item}</p>
<?rb end ?>
END
    @script = <<'END'
 name = @name; items = @items;
 _buf << %Q`<p>Hello #{escape((@name).to_s)}!</p>\n`
for item in @items
 _buf << %Q`<p>#{escape((item).to_s)}</p>\n`
end
END
    @cached = "\#@ARGS name,items\n" + @script
    @template = Tenjin::Template.new(@filepath, :input=>@input)
  end

  def after
    [@filepath, "#{@filepath}.cache"].each do |fpath|
      File.unlink(fpath) if File.exist?(fpath)
    end
  end

  def test_save
    cachefile = @filepath + '.cache'
    spec "save template script and args into cache file." do
      not_ok_(cachefile).exist?
      @cache.save(@filepath, @template)
      ok_(cachefile).exist?
      ok_(File.open(cachefile, 'rb') {|f| f.read }) == @cached
    end
    spec "set cache file's mtime to template timestamp." do
      t = Time.now - 30
      @template.timestamp = t
      @cache.save(@filepath, @template)
      ok_(File.mtime(cachefile).inspect) == t.inspect
    end
  end

  def test_load
    filepath = @filepath
    cachepath = @filepath + '.cache'
    File.open(filepath, 'wb') {|f| f.write(@input) }
    File.open(cachepath, 'wb') {|f| f.write(@cached) }
    ts = nil
    spec "load template data from cache file." do
      ts = File.mtime(cachepath)
      File.utime(ts-9, ts-9, filepath)
      ret = @cache.load(filepath, ts)
      ok_(ret).is_a?(Array)
      args = ['name', 'items']
      spec "get template args data from cached data."
      spec "return script and template args." do
        ok_(ret) == [@script, args]
      end
    end
    spec "if timestamp of cache file is different from template file, return nil" do
      File.utime(ts, ts, filepath)
      File.utime(ts, ts, cachepath)
      ok_(@cache.load(filepath, ts + 1)) == nil
    end
    spec "if template file is not found, return nil." do
      File.rename(cachepath, cachepath + '.bkup')
      begin
        ok_(@cache.load(filepath, ts)) == nil
      ensure
        File.rename(cachepath + '.bkup', cachepath)
      end
    end
  end

end


if __FILE__ == $0
  Oktest.run_all()
end
