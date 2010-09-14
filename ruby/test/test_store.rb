###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"
require 'fileutils'
require 'oktest'


class KeyValueStoreTest
  include Oktest::TestCase

  def before
    @store = Tenjin::MemoryBaseStore.new()
  end

  def test_setter
    @store['key1'] = 'value1'
    ok_(@store.get('key1')) == 'value1'
  end

  def test_getter
    @store.set('key1', 'value1')
    ok_(@store['key1']) == 'value1'
    ok_(@store['key9']) == nil
  end

end


class MemoryBaseStoreTest
  include Oktest::TestCase

  def before
    @store = Tenjin::MemoryBaseStore.new()
    @key   = "foo/123[456]"
    @value = "FOOOOOO"
  end

  def test_set
    spec "store key and value with current and expired timestamp" do
      now = Time.now
      @store.set(@key, @value)
      ok_(@store.values.length) == 1
      #ok_(now, now + @store.lifetime], @store.values[@key]) == [@value
      ok_(@store.values[@key].inspect) == [@value, now, now + @store.lifetime].inspect
    end
  end

  def test_get
    now = Time.now
    @store.set(@key, @value)
    spec "return cache data" do
      ok_(@store.get(@key)) == @value
    end
    spec "if cache data is not found, return nil" do
      ok_(@store.get('hogehoge')) == nil
    end
    spec "if cache data is older than original data, remove it and return nil" do
      ok_(@store.get(@key, now - 1)) == @value  # cache data is newer than original
      ok_(@store.values.length) == 1
      ok_(@store.get(@key, now + 1)) == nil  # cache data is older than original
      ok_(@store.values.length) == 0
    end
    spec "if cache data is expired then remove it and return nil" do
      @store.set(@key, @value)
      @store.values[@key][-1] = now - 1
      ok_(@store.get(@key)) == nil
      ok_(@store.values.length) == 0
    end
  end

  def test_del
    @store.set(@key, @value)
    spec "remove data" do
      ok_(@store.values.length) == 1
      @store.del(@key)
      ok_(@store.values.length) == 0
    end
    spec "don't raise error even if key doesn't exist" do
      not_ok_(proc { @store.del(@key) }).raise?(Exception)
    end
  end

  def test_has?
    spec "if key exists then return true else return false" do
      ok_(@store.has?(@key)) == false
      @store.set(@key, @value)
      ok_(@store.has?(@key)) == true
    end
  end



end


class FileBaseStoreTest
  include Oktest::TestCase

  def before
    @klass = Tenjin::FileBaseStore
    @cachedir = '.test.store'
    Dir.mkdir(@cachedir)
    @store = @klass.new(@cachedir)
    @key = "foo/123[456]"
    @data = "FOOOOO"
    @fpath = @store.filepath(@key)
  end

  def after
    FileUtils.rm_rf(@cachedir)
  end

  def test_initialize
    spec "if passed root dir doesn't exist then raise error" do
      ok_(proc { @klass.new('/voo/doo') }).raise?(ArgumentError, "/voo/doo: not found.")
    end
    spec "if passed non-directory then raise error" do
      ok_(proc { @klass.new(__FILE__) }).raise?(ArgumentError, "#{__FILE__}: not a directory.")
    end
    spec "if path ends with '/' then remove it" do
      ok_(@klass.new(@cachedir + '/').root) == @cachedir
    end
  end

  def test_filepath
    spec "return file path for cache key" do
      store = @klass.new(@cachedir)
      cache_key = "obj/123[456]"
      ok_(store.filepath(cache_key)) == "#{@cachedir}/obj/123_456_"
    end
  end

  def test_set
    store, key, data, fpath = @store, @key, @data, @fpath
    spec "create directory for cache" do
      not_ok_("#{@cachedir}/foo").exist?
      not_ok_(fpath).exist?
      store.set(key, data)
      ok_("#{@cachedir}/foo").dir?
      ok_(fpath).file?
    end
    spec "create temporary file and rename it to cache file (in order not to flock)" do
      # pass
    end
    spec "set mtime (which is regarded as cache expired timestamp)" do
      store.set(key, data)
      ts = Time.now + store.lifetime
      #ok_(File.mtime(fpath)) == ts
      ok_(File.mtime(fpath).to_s) == ts.to_s
      now = Time.now
      store.set(key, data, 30)
      now2 = Time.now
      if now != now2
        store.set(key, data, 30)
        now = now2
      end
      #ok_(File.mtime(fpath)) == now + 30
      ok_(File.mtime(fpath).to_s) == (now + 30).to_s
    end
  end

  def test_get
    store, key, data, fpath = @store, @key, @data, @fpath
    now = Time.now
    store.set(key, data)
    ok_(store.filepath(key)).exist?
    spec "if cache file is not found, return nil" do
      ok_(store.get("kkkk")) == nil
    end
    spec "returns cache file content" do
      ok_(store.get(key)) == data
    end
    spec "if cache file is older than original data, remove it and return nil" do
      ok_(store.get(key, now-1)) == data # cache is newer than original
      ok_(fpath).exist?
      ok_(store.get(key, now+1)) == nil # cache is older than original
      not_ok_(fpath).exist?
    end
    spec "if cache file is expired then remove it and return nil" do
      store.set(key, data)
      ok_(store.get(key)) == data   # not expired
      ts = Time.now - 1
      File.utime(ts, ts, fpath)            # expire cache file
      ok_(store.get(key)) == nil
    end
  end

  def test_del
    store, key, data, fpath = @store, @key, @data, @fpath
    spec "delete data file" do
      store.set(key, data)
      ok_(fpath).exist?
      store.del(key)
      not_ok_(fpath).exist?
    end
    spec "if data file doesn't exist, don't raise error" do
      not_ok_(proc { store.del(key) }).raise?(Exception)
    end
  end

  def test_has?
    spec "if key exists then return true else return false" do
      ok_(@store.has?(@key)) == false
      @store.set(@key, @value)
      ok_(@store.has?(@key)) == true
    end
  end



end


if __FILE__ == $0
  Oktest.run_all()
end
