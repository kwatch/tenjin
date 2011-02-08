###
### $Release:$
### $Copyright$
###

from oktest import ok, not_ok, run
import sys, os, re, time, shutil
from testcase_helper import *
from oktest import *

import tenjin
from tenjin.helpers import *

if python2:
    def _read_file(filepath):
        f = open(filepath, 'rb')
        try:
            return f.read()
        finally:
            f.close()
elif python3:
    def _read_file(filepath):
        f = open(filepath, encoding='utf-8')
        try:
            return f.read()
        finally:
            f.close()


class MemoryBaseStoreTest(object):

    def before(self):
        self.data_cache = tenjin.MemoryBaseStore()
        self.key = 'values/foo'
        self.value = "FOOBAR"

    def test_set(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        if "called then caches value":
            ok (key).not_in(data_cache.values)
            data_cache.set(key, value, 1)
            ok (key).in_(data_cache.values)
        if "called with lifetime then set cache file's mtime as lifetime seconds ahead":
            data_cache.set(key, value, 10)
            now = time.time()
            t = data_cache.values[key]
            ok (t).is_a(tuple)
            ok (t[0]) == value
            ok (int(t[1])) == int(now)
            ok (int(t[2])) == int(now+10)
        if "called without lifetime then set cache file's mtime as 1 week ahead":
            data_cache.set(key, value)
            now = time.time()
            t = data_cache.values[key]
            ok (t[0]) == value
            ok (int(t[1])) == int(now)
            ok (t[2]) == 0

    def test_get(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        if "called before data set then returns None":
            ok (data_cache.get(key)) == None
        if "called after data set then returns value":
            data_cache.set(key, value, 1)
            ok (data_cache.get(key)) == value
        if "called after lifetime seconds passed then retunrs None":
            time.sleep(2)
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


class FileBaseStoreTest(object):

    def before(self):
        self.root_dir = '_test.caches.d'
        os.mkdir(self.root_dir)
        self.data_cache = tenjin.FileBaseStore(self.root_dir)
        self.key = 'values/foo'
        self.value = "FOOBAR"

    def after(self):
        shutil.rmtree(self.root_dir)

    def test_set(self):
        data_cache, key, value = self.data_cache, self.key, self.value
        cache_fpath = self.root_dir + '/' + self.key
        if "called then create cache file":
            not_ok (cache_fpath).is_file()
            data_cache.set(key, value, 1)
            ok (cache_fpath).is_file()
            ok (_read_file(cache_fpath)) == value
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


class FragmentCacheTest(object):

    def before(self):
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
        self.tmpfiles = [self.tname]
        write_file(self.tname, pyhtml)
        self.root_dir = '_test.caches.d'
        os.mkdir(self.root_dir)
        #data_cache = tenjin.FileBaseStore(self.root_dir)
        #self.fragment_cache = tenjin.FragmentCacheHelper(data_cache, prefix='fragment.')
        #global not_cached, echo_cached
        #not_cached  = self.fragment_cache.not_cached
        #echo_cached = self.fragment_cache.echo_cached
        self._orig_store  = tenjin.helpers.fragment_cache.store
        self._orig_preifx = tenjin.helpers.fragment_cache.prefix
        tenjin.helpers.fragment_cache.store = tenjin.FileBaseStore(self.root_dir)
        tenjin.helpers.fragment_cache.prefix = 'fragment.'

    def after(self):
        for tmpfile in self.tmpfiles:
            for fname in [tmpfile, tmpfile + '.cache']:
                if os.path.exists(fname):
                    os.unlink(fname)
        shutil.rmtree(self.root_dir)
        tenjin.helpers.fragment_cache.store  = self._orig_store
        tenjin.helpers.fragment_cache.prefix = self._orig_preifx

    def test_init(self):
        if "lifetime is None or not specified then default value is used":
            def chk(frag_cache):
                ok ('lifetime' in frag_cache.__dict__) == False
                ok (frag_cache.lifetime) == tenjin.FragmentCacheHelper.lifetime
            chk(tenjin.FragmentCacheHelper(None, ))
            chk(tenjin.FragmentCacheHelper(None, lifetime=None))
        if "lifetime is specified then it is used":
            frag_cache = tenjin.FragmentCacheHelper(None, lifetime=0)
            ok (frag_cache.lifetime) == 0
            ok (frag_cache.lifetime) != tenjin.FragmentCacheHelper.lifetime
        if "prefix is None or not specified then default value is used":
            def chk(frag_cache):
                ok ('prefix' in frag_cache.__dict__) == False
                ok (frag_cache.prefix) == tenjin.FragmentCacheHelper.prefix
            chk(tenjin.FragmentCacheHelper(None, ))
            chk(tenjin.FragmentCacheHelper(None, prefix=None))
        if "lifetime is specified then it is used":
            frag_cache = tenjin.FragmentCacheHelper(None, prefix='frg/')
            ok (frag_cache.prefix) == 'frg/'
            ok (frag_cache.prefix) != tenjin.FragmentCacheHelper.prefix

    def test_not_cached_and_echo_cached(self):
        expected, tname = self.expected, self.tname
        engine = tenjin.Engine(cache=False)
        if "called 1st time then cache file should be created":
            context = {'x': 3}
            output = engine.render(tname, context)
            ok (output) == expected
            cache_fpath = self.root_dir + '/fragment.value/x'
            ok (cache_fpath).is_file()
            ok (_read_file(cache_fpath)) == "<p>x=3</p>\n"
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
            ok (_read_file(cache_fpath)) == "<p>x=4</p>\n"

    def test_functions(self):
        fragment_cache = tenjin.helpers.fragment_cache
        tupl = fragment_cache.functions()
        ok (tupl[0]) == fragment_cache.not_cached
        ok (tupl[1]) == fragment_cache.echo_cached

    def test_cache_as(self):
        input = r"""
<div>
<?py for _ in cache_as('items/123', 2): ?>
  <ul>
    <?py for item in items: ?>
    <li>${item}</li>
    <?py #endfor ?>
  </ul>
<?py #endfor ?>
</div>
"""[1:]
        expected_fragment = r"""
  <ul>
    <li>A</li>
    <li>B</li>
  </ul>
"""[1:]
        expected_html = "<div>\n" + expected_fragment + "</div>\n"
        file_name = "_test_cache_as.pyhtml"
        f = open(file_name, "w")
        f.write(input)
        f.close()
        engine = tenjin.Engine()
        self.tmpfiles.append(file_name)
        fragment_cache_path = self.root_dir + '/fragment.items/123'
        #
        ts = None
        if "called at first time then cache fragment into file":
            context = {'items': ['A','B']}
            output = engine.render(file_name, context)
            ok (output) == expected_html
            ok (fragment_cache_path).is_file()
            ok (_read_file(fragment_cache_path)) == expected_fragment
            ts = os.path.getmtime(fragment_cache_path)
        if "called at second time within lifetime then dont't render":
            #now = time.time()
            #os.utime(fragment_cache_path, (now-1, now-1))
            time.sleep(1)
            context = {'items': ['X','Y']}   # new context data
            output = engine.render(file_name, context)
            ok (output) == expected_html     # not changed
            ok (os.path.getmtime(fragment_cache_path)) == ts
        if "called after lifetime expired then render again":
            #os.utime(fragment_cache_path, (now-3, now-3))
            time.sleep(2)
            context = {'items': ['X','Y']}   # new context data
            output = engine.render(file_name, context)
            edit = lambda s: s.replace('A', 'X').replace('B', 'Y')
            ok (output) == edit(expected_html)   # changed!
            ok (_read_file(fragment_cache_path)) == edit(expected_fragment)  # changed!
            ok (os.path.getmtime(fragment_cache_path)) > ts


if __name__ == '__main__':
    run()
