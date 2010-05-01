###
### $Release:$
### $Copyright$
###

import unittest
from oktest import ok, not_ok
import sys, os, re, time, shutil
from testcase_helper import *
from oktest import *

import tenjin
from tenjin.helpers import *


class MemoryBaseStoreTest(unittest.TestCase):

    def setUp(self):
        self.data_cache = tenjin.MemoryBaseStore()
        self.key = 'values/foo'
        self.value = "FOOBAR"

    def test_set(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        if "called then cachees value":
            ok (key).not_in(data_cache.values)
            data_cache.set(key, value, 1)
            ok (key).in_(data_cache.values)
        if "called with lifetime then set cache file's mtime as lifetime seconds ahead":
            data_cache.set(key, value, 10)
            now = time.time()
            t = data_cache.values[key]
            ok (t).is_a(tuple)
            ok (t[0]) == value
            ok (int(t[1])) == int(now+10)
        if "called without lifetime then set cache file's mtime as 1 week ahead":
            data_cache.set(key, value)
            ok (data_cache.values[key]) == (value, 0)

    def test_get(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        if "called before data set then returns None":
            ok (data_cache.get(key)) == None
        if "called after data set then returns value":
            data_cache.set(key, value, 1)
            ok (data_cache.get(key)) == value
        if "called after lifetime seconds passed then retunrs None":
            time.sleep(1)
            ok (data_cache.get(key)) == None
        if "called after lifetime seconds passed then remove cache data":
            ok (key).not_in(data_cache.values)

    def test_delete(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        if "called then remove cache file and returns True if it exists":
            data_cache.set(key, value, 1)
            ok (key).in_(data_cache.values)    # pre_cond
            ok (data_cache.delete(key)) == True
            ok (key).not_in(data_cache.values)
        if "called when cache file not exist then returns False":
            ok (data_cache.delete(key)) == False

    def test_has(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        if "key not exist then returns False":
            ok (data_cache.has(key)) == False
        if "key exists and not expired then returns True":
            data_cache.set(key, value, 1)
            ok (data_cache.has(key)) == True
        if "key exists but is expired then remove cache data and returns False":
            ok (key).in_(data_cache.values)   # pre_cond
            time.sleep(1)
            ok (data_cache.has(key)) == False
            ok (key).not_in(data_cache.values)


class FileBaseStoreTest(unittest.TestCase):

    def setUp(self):
        self.root_dir = '_test.caches.d'
        os.mkdir(self.root_dir)
        self.data_cache = tenjin.FileBaseStore(self.root_dir)
        self.key = 'values/foo'
        self.value = "FOOBAR"

    def tearDown(self):
        shutil.rmtree(self.root_dir)

    def test_set(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        cache_fpath = self.root_dir + '/' + self.key
        if "called then create cache file":
            not_ok (cache_fpath).is_file()
            data_cache.set(key, value, 1)
            ok (cache_fpath).is_file()
            ok (read_file(cache_fpath, 'rb')) == value
        if "called with lifetime then set cache file's mtime as lifetime seconds ahead":
            data_cache.set(key, value, 10)
            ok (int(os.path.getmtime(cache_fpath))) == int(time.time()) + 10
        if "called without lifetime then set cache file's mtime as 1 week ahead":
            data_cache.set(key, value, 0)
            ok (int(os.path.getmtime(cache_fpath))) == int(time.time()) + 60*60*24*7

    def test_get(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        if "called before data set then returns None":
            ok (data_cache.get(key)) == None
        if "called after data set then returns value":
            data_cache.set(key, value, 1)
            ok (data_cache.get(key)) == value
        if "called after lifetime seconds passed then retunrs None":
            cache_fpath = self.root_dir + '/' + self.key
            ok (cache_fpath).is_file()  # pre_cond
            #time.sleep(1)
            now = time.time(); os.utime(cache_fpath, (now-1, now-1))
            ok (data_cache.get(key)) == None
        if "called after lifetime seconds passed then remove cache file":
            not_ok (cache_fpath).is_file()

    def test_delete(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        cache_fpath = self.root_dir + '/' + self.key
        if "called then remove cache file and returns True if it exists":
            data_cache.set(key, value, 1)
            ok (cache_fpath).is_file()   # pre_cond
            ok (data_cache.delete(key)) == True
            not_ok (cache_fpath).is_file()
        if "called when cache file not exist then returns False":
            ok (data_cache.delete(key)) == False

    def test_has(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        cache_fpath = self.root_dir + '/' + self.key
        if "cache file not exist then returns False":
            ok (data_cache.has(key)) == False
        if "cache file eixsts and not expired then returns True":
            data_cache.set(key, value, 1)
            ok (data_cache.has(key)) == True
        if "cache file eixsts but is expired then remove cache file and returns False":
            ok (cache_fpath).is_file()   # pre_cond
            #time.sleep(1)
            now = time.time(); os.utime(cache_fpath, (now-1, now-1))
            ok (data_cache.has(key)) == False
            not_ok (cache_fpath).is_file()


class FragmentCacheTest(unittest.TestCase):

    def setUp(self):
        pat = re.compile(r'^\t', re.M)
        pyhtml = pat.sub("", """
	<div>
	<?py if not_cached('value/x', 1): ?>
	<p>x=#{x}</p>
	<?py #endif ?>
	<?py echo_cached() ?>
	</div>
	"""[1:])
        self.expected = pat.sub("", """
	<div>
	<p>x=3</p>
	</div>
	"""[1:])
        self.tname = 'index.pyhtml'
        write_file(self.tname, pyhtml)
        self.root_dir = '_test.caches.d'
        os.mkdir(self.root_dir)
        data_cache = tenjin.FileBaseStore(self.root_dir)
        self.fragment_cache = tenjin.FragmentCacheHelper(data_cache, prefix='fragment.')
        global not_cached, echo_cached
        not_cached  = self.fragment_cache.not_cached
        echo_cached = self.fragment_cache.echo_cached

    def tearDown(self):
        os.unlink(self.tname)
        shutil.rmtree(self.root_dir)

    def test_not_cached_and_echo_cached(self):
        expected, tname = self.expected, self.tname
        engine = tenjin.Engine()
        if "called 1st time then cache file should be created":
            context = {'x': 3}
            output = engine.render(tname, context)
            ok (output) == expected
            cache_fpath = self.root_dir + '/fragment.value/x'
            ok (cache_fpath).is_file()
            ok (read_file(cache_fpath, 'rb')) == "<p>x=3</p>\n"
        if "called within lifetime then cache file content should be used":
            context = {'x': 4}
            output = engine.render(tname, context)
            ok (output) == expected  # output should not be changed
        if "called after lifetime seconds passed then cache file content should not be used":
            #time.sleep(1)
            now = time.time(); os.utime(cache_fpath, (now-1, now-1))
            output = engine.render(tname, context)
            expected = expected.replace('x=3', 'x=4')
            ok (output) == expected
            ok (read_file(cache_fpath, 'rb')) == "<p>x=4</p>\n"


if __name__ == '__main__':
    unittest.main()
