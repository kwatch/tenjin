###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"
require 'fileutils'


class KeyValueStoreTest < Test::Unit::TestCase

  def setup
    @store = Tenjin::MemoryBaseStore.new()
  end

  def test_setter
    @store['key1'] = 'value1'
    assert_equal('value1', @store.get('key1'))
  end

  def test_getter
    @store.set('key1', 'value1')
    assert_equal('value1', @store['key1'])
    assert_equal(nil,      @store['key9'])
  end

end


class MemoryBaseStoreTest < Test::Unit::TestCase

  def setup
    @store = Tenjin::MemoryBaseStore.new()
    @key   = "foo/123[456]"
    @value = "FOOOOOO"
  end

  def test_set
    if :"store key and value with current and expired timestamp"
      now = Time.now
      @store.set(@key, @value)
      assert_equal(1, @store.values.length)
      #assert_equal([@value, now, now + @store.lifetime], @store.values[@key])
      assert_equal([@value, now, now + @store.lifetime].inspect, @store.values[@key].inspect)
    end
  end

  def test_get
    now = Time.now
    @store.set(@key, @value)
    if :"called then return cache data"
      assert_equal(@value, @store.get(@key))
    end
    if :"cache data is not found, return nil"
      assert_nil(@store.get('hogehoge'))
    end
    if :"cache data is older than original data, remove it and return nil"
      assert_equal(@value, @store.get(@key, now - 1))  # cache data is newer than original
      assert_equal(1, @store.values.length)
      assert_equal(nil,   @store.get(@key, now + 1))  # cache data is older than original
      assert_equal(0, @store.values.length)
    end
    if :"cache data is expired then remove it and return nil"
      @store.set(@key, @value)
      @store.values[@key][-1] = now - 1
      assert_equal(nil, @store.get(@key))
      assert_equal(0, @store.values.length)
    end
  end

  def test_del
    @store.set(@key, @value)
    if :"called then remove data"
      assert_equal(1, @store.values.length)
      @store.del(@key)
      assert_equal(0, @store.values.length)
    end
    if :"don't raise error even if key doesn't exist"
      assert_nothing_raised do
        @store.del(@key)
      end
    end
  end

  def test_has?
    if :"key exists then return true else return false"
      assert_equal(false, @store.has?(@key))
      @store.set(@key, @value)
      assert_equal(true, @store.has?(@key))
    end
  end

  self.select_target_test()

end


class FileBaseStoreTest < Test::Unit::TestCase

  def setup
    @klass = Tenjin::FileBaseStore
    @cachedir = '.test.store'
    Dir.mkdir(@cachedir)
    @store = @klass.new(@cachedir)
    @key = "foo/123[456]"
    @data = "FOOOOO"
    @fpath = @store.filepath(@key)
  end

  def teardown
    FileUtils.rm_rf(@cachedir)
  end

  def test_initialize
    if :"passed root dir doesn't exist then raises error"
      ex = assert_raises(ArgumentError) do
        @klass.new('/voo/doo')
      end
      assert_equal ex.message, "/voo/doo: not found."
    end
    if :"passed non-directory then raises error"
      ex = assert_raises(ArgumentError) do
        @klass.new(__FILE__)
      end
      assert_equal ex.message, "#{__FILE__}: not a directory."
    end
    if :"path ends with '/' then removes it"
      assert_equal @cachedir, @klass.new(@cachedir + '/').root
    end
  end

  def test_filepath
    if :"called then returns file path for cache key"
      store = @klass.new(@cachedir)
      cache_key = "obj/123[456]"
      assert_equal("#{@cachedir}/obj/123_456_", store.filepath(cache_key))
    end
  end

  def test_set
    store, key, data, fpath = @store, @key, @data, @fpath
    if :"create directory for cache"
      assert_not_exist(fpath)
      store.set(key, data)
      assert_dir_exist(fpath)
    end
    if :"create temporary file and rename it to cache file (in order not to flock)"
      # pass
    end
    if :"set mtime (which is regarded as cache expired timestamp)"
      store.set(key, data)
      ts = Time.now + store.lifetime
      #assert_equal(ts, File.mtime(fpath))
      assert_equal(ts.to_s, File.mtime(fpath).to_s)
      now = Time.now
      store.set(key, data, 30)
      now2 = Time.now
      if now != now2
        store.set(key, data, 30)
        now = now2
      end
      #assert_equal(now + 30, File.mtime(fpath))
      assert_equal((now + 30).to_s, File.mtime(fpath).to_s)
    end
  end

  def test_get
    store, key, data, fpath = @store, @key, @data, @fpath
    now = Time.now
    store.set(key, data)
    assert_file_exist(store.filepath(key))
    if :"cache file is not found, return nil"
      assert_nil(store.get("kkkk"))
    end
    if :"called then returns cache file content"
      assert_equal(data, store.get(key))
    end
    if :"if cache file is older than original data, remove it and return nil"
      assert_equal(data, store.get(key, now-1)) # cache is newer than original
      assert_file_exist(fpath)
      assert_equal(nil,  store.get(key, now+1)) # cache is older than original
      assert_not_exist(fpath)
    end
    if :"if cache file is expired then remove it and return nil"
      store.set(key, data)
      assert_equal(data, store.get(key))   # not expired
      ts = Time.now - 1
      File.utime(ts, ts, fpath)            # expire cache file
      assert_equal(nil,  store.get(key))
    end
  end

  def test_del
    store, key, data, fpath = @store, @key, @data, @fpath
    if :"called then delete data file"
      store.set(key, data)
      assert_file_exist(fpath)
      store.del(key)
      assert_not_exist(fpath)
    end
    if :"data file doesn't exist, don't raise error"
      assert_nothing_raised do
        store.del(key)
      end
    end
  end

  def test_has?
    if :"key exists then return true else return false"
      assert_equal(false, @store.has?(@key))
      @store.set(@key, @value)
      assert_equal(true, @store.has?(@key))
    end
  end

  self.select_target_test()

end
