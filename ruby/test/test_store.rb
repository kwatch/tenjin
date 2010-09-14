###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"
require 'fileutils'


class FileBaseStoreTest < Test::Unit::TestCase

  def _change_mtime(fname, sec)
    atime = File.atime(fname)
    mtime = File.mtime(fname)
    File.utime(atime, mtime + sec, fname)
  end

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

  def test_get
    store, key, data, fpath = @store, @key, @data, @fpath
    store.set(key, data)
    assert_file_exist(store.filepath(key))
    if :"cache file is not found, return nil"
      assert_nil(store.get("kkkk"))
    end
    if :"called then returns cache file content"
      assert_equal(data, store.get(key))
    end
    if :"cache file is older than max_timestamp, return nil"
      ts = File.mtime(fpath)
      assert_nil(store.get(key, ts-1))
      assert_equal(data, store.get(key, ts))
    end
    if :"cache file is expired, return nil"
      ts = Time.now - 1
      File.utime(ts, ts, fpath)
      assert_nil(store.get(key))
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


end
