###
### $Release:$
### $Copyright$
###

from oktest import ok, not_ok, run
import sys, os, re, time, marshal
from glob import glob
try:    import cPickle as pickle
except: import pickle

from testcase_helper import *
import tenjin
#from tenjin.helpers import escape, to_str
from tenjin.helpers import *


def _convert_data(data, lang='python'):
    if isinstance(data, dict):
        for k in list(data.keys()):
            v = data[k]
            if k[-1] == '*':
                ok (v).is_a(dict)
                data[k[:-1]] = v.get(lang)
            if isinstance(v, dict) and lang in v:
                data[k] = v[lang]
            else:
                _convert_data(v, lang)
    elif isinstance(data, list):
        for k, v in enumerate(data):
            if isinstance(v, dict) and lang in v:
                data[k] = v[lang]
            else:
                _convert_data(v, lang)


def _remove_files(basenames=[]):
    for basename in basenames:
        for filename in glob("%s*" % basename):
            os.unlink(filename)


class EngineTest(object):

    #code = TestCaseHelper.generate_testcode(__file__)
    #exec(code)
    datalist = TestCaseHelper.load_testdata(__file__)
    testdata = dict([ (d['name'], d) for d in datalist ])
    _convert_data(testdata, lang='python')
    data = testdata['basic']
    for d in data['templates']:
        d['filename'] = d['filename'].replace('.xxhtml', '.pyhtml')
    templates = dict([(hash['filename'], hash['content']) for hash in data['templates']])
    expected  = dict([(hash['name'], hash['content']) for hash in data['expected']])
    contexts  = data['contexts']


    def before(self):
        tenjin.Engine.cache.clear()
    #    testdata = EngineTest.testdata['basic']
    #    for hash in testdata['templates']:
    #        write_file(hash['filename'], hash['content'])


    #def after(self):
    #    for hash in EngineTest.testdata['basic']['templates']:
    #        filename = hash['filename']
    #        for fname in [filename, filename+'.cache', filename+'.marshal']:
    #            if os.path.exists(fname):
    #                os.unlink(fname)


    def _testname(self):
        try:
            return self._TestCase__testMethodName
        except AttributeError:
            return self._testMethodName

    def _test_basic(self):
        try:
            testdata = EngineTest.testdata['basic']
            for hash in testdata['templates']:
                write_file(hash['filename'], hash['content'])
            #
            testname = self._testname()
            lst = testname[len('test_basic'):].split('_')
            action   = lst[1]                # 'list', 'show', 'create', or 'edit'
            shortp   = lst[2] == 'short'     # 'short' or 'long'
            layoutp  = lst[3] != 'nolayout'  # 'nolayout' or 'withlayout'
            layout   = layoutp and 'user_layout.pyhtml' or None
            engine   = tenjin.Engine(prefix='user_', postfix='.pyhtml', layout=layout)
            context  = EngineTest.contexts[action].copy()
            key      = 'user_' + action + (layout and '_withlayout' or '_nolayout')
            expected = EngineTest.expected[key]
            filename = 'user_%s.pyhtml' % action
            tplname  = shortp and ':'+action or filename
            if layout:
                output = engine.render(tplname, context)
            else:
                output = engine.render(tplname, context, layout=False)
            ok (output) == expected
        finally:
            filenames = [ hash['filename'] for hash in EngineTest.testdata['basic']['templates'] ]
            _remove_files(filenames)
            #for hash in EngineTest.testdata['basic']['templates']:
            #    filename = hash['filename']
            #    for fname in [filename, filename+'.cache', filename+'.marshal']:
            #        if os.path.exists(fname):
            #            os.unlink(fname)


    ## long, nolayout

    def test_basic_list_long_nolayout(self):
        self._test_basic()

    def test_basic_show_long_nolayout(self):
        self._test_basic()

    def test_basic_create_long_nolayout(self):
        self._test_basic()

    def test_basic_edit_long_nolayout(self):
        self._test_basic()


    ## short, nolayout

    def test_basic_list_short_nolayout(self):
        self._test_basic()

    def test_basic_show_short_nolayout(self):
        self._test_basic()

    def test_basic_create_short_nolayout(self):
        self._test_basic()

    def test_basic_edit_short_nolayout(self):
        self._test_basic()


    ## long, withlayout

    def test_basic_list_long_withlayout(self):
        self._test_basic()

    def test_basic_show_long_withlayout(self):
        self._test_basic()

    def test_basic_create_long_withlayout(self):
        self._test_basic()

    def test_basic_edit_long_withlayout(self):
        self._test_basic()


    ## short, withlayout

    def test_basic_list_short_withlayout(self):
        self._test_basic()

    def test_basic_show_short_withlayout(self):
        self._test_basic()

    def test_basic_create_short_withlayout(self):
        self._test_basic()

    def test_basic_edit_short_withlayout(self):
        self._test_basic()


    ## ----------------------------------------


    def test_capture_and_echo(self):
        hash = EngineTest.testdata['test_capture_and_echo']
        layout = hash['layout']
        content = hash['content']
        expected = hash['expected']
        layout_filename = 'user_layout.pyhtml'
        content_filename = 'user_content.pyhtml'
        context = { 'items': ['AAA', 'BBB', 'CCC'] }
        try:
            write_file(layout_filename, layout)
            write_file(content_filename, content)
            engine = tenjin.Engine(prefix='user_', postfix='.pyhtml', layout=':layout')
            output = engine.render(':content', context)
            ok (output) == expected
        finally:
            _remove_files([layout_filename, content_filename])


    def test_captured_as(self):
        hash = EngineTest.testdata['test_captured_as']
        files = ( ('content.pyhtml',      hash['content']),
                  ('customlayout.pyhtml', hash['customlayout']),
                  ('baselayout.pyhtml',   hash['baselayout']),
                  )
        context = hash['context']
        expected = hash['expected']
        try:
            for filename, content in files:
                write_file(filename, content)
            engine = tenjin.Engine(postfix='.pyhtml')
            output = engine.render(':content', context)
            ok (output) == expected
        finally:
            _remove_files([ t[0] for t in files ])


    def test_local_layout(self):
        hash = EngineTest.testdata['test_local_layout']
        context = hash['context']
        names = ['layout_html', 'layout_xhtml', 'content_html']
        def fname(base):
            return 'local_%s.pyhtml' % base
        try:
            interval = tenjin.Engine.timestamp_interval
            tenjin.Engine.timestamp_interval = 0
            for name in names:
                write_file(fname(name), hash[name])
            engine = tenjin.Engine(prefix='local_', postfix='.pyhtml', layout=':layout_html')
            ##
            def _test(expected, statement):
                content_html = hash['content_html'] + statement
                write_file(fname('content_html'), content_html)
                actual = engine.render(':content_html', context)
                ok (actual) == expected
            ##
            _test(hash['expected_html'], '')
            time.sleep(1)
            _test(hash['expected_xhtml'], "<?py _context['_layout'] = ':layout_xhtml' ?>\n")
            time.sleep(1)
            _test(hash['expected_nolayout'], "<?py _context['_layout'] = False ?>\n")
            ##
        finally:
            tenjin.Engine.timestamp_interval = interval
            #for name in names:
            #    for suffix in ['', '.cache', '.marshal']:
            #        filename = fname(name) + suffix
            #        if os.path.isfile(filename):
            #            os.unlink(filename)
            _remove_files([ fname(name) for name in names ])


    def test_cachefile(self):
        data = EngineTest.testdata['test_cachefile']
        filenames = { 'layout': 'layout.pyhtml',
                      'page': 'account_create.pyhtml',
                      'form': 'account_form.pyhtml',
                    }
        expected = data['expected']
        context = { 'params': { } }
        cache_filenames = ['account_create.pyhtml.cache', 'account_form.pyhtml.cache']
        try:
            for key, filename in filenames.items():
                write_file(filename, data[key])
            props = { 'prefix':'account_', 'postfix':'.pyhtml', 'layout':'layout.pyhtml' }
            ## no caching
            props['cache'] = False
            engine = tenjin.Engine(**props)
            output = engine.render(':create', context)
            ok (output) == expected
            for fname in cache_filenames: not_ok (fname).exists()
            ## marshal caching
            props['cache'] = True
            engine = tenjin.Engine(**props)
            output = engine.render(':create', context)
            ok (output) == expected
            if   python2:  nullbyte = '\0'
            elif python3:  nullbyte = '\0'.encode('ascii')
            for fname in cache_filenames:
                ok (fname).exists()                         # file created?
                s = read_file(fname, 'rb')                       # read binary file
                ok (s.find(nullbyte)) >= 0           # binary file?
                f = lambda: marshal.load(open(fname, 'rb'))
                ok (f).not_raise()                           # marshal?
            engine = tenjin.Engine(**props)
            output = engine.render(':create', context)
            ok (output) == expected               # reloadable?
            #
            for fname in glob('*.pyhtml.cache'): os.unlink(fname)
            for fname in cache_filenames:
                not_ok (fname).exists()
            ## pickle caching
            props['cache'] = tenjin.PickleCacheStorage()
            engine = tenjin.Engine(**props)
            output = engine.render(':create', context)
            ok (output) == expected
            if   python2:  nullbyte = '\0'
            elif python3:  nullbyte = '\0'.encode('ascii')
            for fname in cache_filenames:
                ok (fname).exists()                         # file created?
                s = read_file(fname, 'rb')                       # read text file
                if python2:
                    ok (s.find(nullbyte)) < 0        # text file? (pickle protocol ver 2)
                elif python3:
                    ok (s.find(nullbyte)) >= 0       # binary file? (pickle protocol ver 3)
                f = lambda: Pickle.load(open(fname, 'rb'))
                ok (f).not_raise(ValueError)
                pickle.load(open(fname, 'rb'))
            engine = tenjin.Engine(**props)
            output = engine.render(':create', context)
            ok (output) == expected               # reloadable?
            #
            for fname in glob('*.cache'): os.unlink(fname)
            for fname in cache_filenames:
                not_ok (fname).exists()
            ## text caching
            props['cache'] = tenjin.TextCacheStorage()
            engine = tenjin.Engine(**props)
            output = engine.render(':create', context)
            ok (output) == expected
            if   python2:  nullchar = '\0'
            elif python3:  nullchar = '\0'
            for fname in cache_filenames:
                ok (fname).exists()                  # file created?
                s = read_file(fname, 'r')            # read text file
                ok (s.find(nullchar)) < 0            # text file?
                #f = lambda: marshal.loads(s)
                f = lambda: marshal.load(open(fname, 'rb'))
                if python3:
                    ok (f).raises(ValueError)        # non-marshal?
                    if sys.version_info[1] == 0:     # python 3.0
                        ok (str(f.exception)) == "bad marshal data"
                    else:                            # python 3.1 or later
                        ok (str(f.exception)) == "bad marshal data (unknown type code)"
                elif python2 and sys.version_info[1] >= 5:
                    ok (f).raises(EOFError, "EOF read where object expected")  # non-marshal?
            engine = tenjin.Engine(**props)
            output = engine.render(':create', context)
            ok (output) == expected                  # reloadable?
        finally:
            _remove_files(filenames.values())

    def test_cachefile_timestamp(self):
        """engine should clear cache not only template is newer but also template is older than cache."""
        data = EngineTest.testdata['test_cachefile']
        filenames = { 'layout': 'layout.pyhtml',
                      'page': 'account_create.pyhtml',
                      'form': 'account_form.pyhtml',
                    }
        expected = data['expected']
        context = { 'params': { } }
        cache_filenames = ['account_create.pyhtml.cache', 'account_form.pyhtml.cache']
        try:
            interval = tenjin.Engine.timestamp_interval
            tenjin.Engine.timestamp_interval = 0
            for key, filename in filenames.items():
                write_file(filename, data[key])
            props = { 'prefix': 'account_', 'postfix':'.pyhtml', 'layout':'layout.pyhtml', 'cache':True }
            ## create cache files and check them
            time.sleep(1)
            curr_time = time.time()
            engine = tenjin.Engine(**props)
            output = engine.render(':create', context)
            for fname in filenames.values():
                ok (fname).exists()                         # file created?
                ok (engine.get_template(fname).timestamp) < curr_time
                ok (engine.get_template(fname).timestamp) == os.path.getmtime(fname)
            ## save current cached object
            cached = {}
            for fname in filenames.values():
                cached[fname] = engine.get_template(fname)
            ## confirm that get_template() returns the same object
            for fname in filenames.values():
                ok (cached[fname]).is_(engine.get_template(fname))
            ## change timestamp of templates to be old
            for fname in filenames.values():
                atime = mtime = os.path.getmtime(fname) - 10
                os.utime(fname, (atime, mtime))
            ## check whether new caches are created
            for fname in filenames.values():
                t = engine.get_template(fname)
                not_ok (cached[fname]).is_(t)
                ok (t.timestamp) == os.path.getmtime(fname)
        finally:
            tenjin.Engine.timestamp_interval = interval
            _remove_files(filenames.values())


    def test_cachefile_unset(self):
        try:
            input = "<?py x = 10 ?>"
            template_name = "cachefile_delete.pyhtml"
            open(template_name, 'w').write(input)
            storage = tenjin.MarshalCacheStorage()
            engine = tenjin.Engine(cache=storage)
            engine.render(template_name)
            fullpath = os.path.abspath(template_name)
            ok (storage.items).contains(fullpath)
            ok (template_name + '.cache').exists()
            storage.unset(fullpath)
            not_ok (storage.items).contains(fullpath)
            not_ok (template_name + '.cache').exists()
            def f():
                storage.unset(fullpath)
            ok (f).not_raise()
        finally:
            _remove_files([template_name, template_name+'.cache'])


    def test_change_layout(self):
        data = EngineTest.testdata['test_change_layout']
        ## setup
        tenjin.Engine.cache.clear()
        basenames = ['baselayout', 'customlayout', 'content']
        for basename in basenames:
            write_file('%s.pyhtml' % basename, data[basename])
        ## body
        try:
            engine = tenjin.Engine(layout='baselayout.pyhtml')
            output = engine.render('content.pyhtml')
            expected = data['expected']
            ok (output) == expected
        ## teardown
        finally:
            _remove_files(basenames)


    def test_context_scope(self):
        data = EngineTest.testdata['test_context_scope']
        base = data['base']
        part = data['part']
        expected = data['expected']
        for basename in ('base', 'part'):
            write_file('%s.pyhtml' % basename, data[basename])
        #
        try:
            engine = tenjin.Engine()
            context = {}
            output = engine.render('base.pyhtml', context)
            expected = data['expected']
            ok (output) == expected
        finally:
            _remove_files(['base', 'part'])


    def test_template_args(self):
        data = EngineTest.testdata['test_template_args']
        content = data['content']
        expected = data['expected']
        context = data['context']
        for basename in ('content', ):
            write_file('%s.pyhtml' % basename, data[basename])
        #
        try:
            def f1():
                engine = tenjin.Engine(cache=True)
                ok (engine.get_template('content.pyhtml').args) != None
                output = engine.render('content.pyhtml', context)
            ok (f1).raises(NameError); ex = f1.exception
            #import sys; sys.stderr.write("*** debug: ex=%s\n" % (repr(ex)))
            #engine = tenjin.Engine(cache=True)
            #ok (engine.get_template('content.pyhtml').args) != None
            #output = engine.render('content.pyhtml', context)
            #ok (output) == expected
            ok (f1).raises(NameError); ex = f1.exception
        finally:
            _remove_files(['content'])


    def test__set_cache_storage(self):
        if "default then Engine.cache is MarshalCacheStorage instance":
            ok (tenjin.Engine.cache).is_a(tenjin.MarshalCacheStorage)
        if "cache=True specified then use default cache object":
            engine = tenjin.Engine(cache=True)
            ok ('cache' in engine.__dict__) == False
            ok (engine.cache).is_(tenjin.Engine.cache)
            ok (engine.cache).is_(tenjin.Engine(cache=True).cache)
        #if "cache=None specified then set MemoryCacheObject instance as cache object":
        #    engine = tenjin.Engine(cache=None)
        #    ok ('cache' in engine.__dict__) == True
        #    ok (engine.cache).is_a(tenjin.MemoryCacheStorage)
        if "cache=None means same as cache=True":
            engine = tenjin.Engine(cache=None)
            ok ('cache' in engine.__dict__) == False
        if "cache=False specified then don't use cache object":
            engine = tenjin.Engine(cache=False)
            ok ('cache' in engine.__dict__) == True
            ok (engine.cache) == None
        if "CacheStorage instance is specified then use it as cache object":
            cache_storage = tenjin.MarshalCacheStorage()
            engine = tenjin.Engine(cache=cache_storage)
            ok ('cache' in engine.__dict__) == True
            ok (engine.cache).is_(cache_storage)
        if "invalid object is specified as cache object then raise ValueError":
            def f():
                tenjin.Engine(cache=123)
            ok (f).raises(ValueError, '123: invalid cache object.')


    def test_cached_contents(self):
        data = EngineTest.testdata['test_cached_contents']
        def _test(filename, cachename, cachemode, input, expected_script, expected_args):
            if input:
                write_file(filename, input)
            engine = tenjin.Engine(cache=cachemode)
            t = engine.get_template(filename)
            ok (t.args) == expected_args
            ok (t.script) == expected_script
            import marshal
            dct = marshal.load(open(filename + '.cache', 'rb'))
            ok (dct['args']) == expected_args
            ok (dct['script']) == expected_script
        ##
        try:
            ## args=[x,y,z], cache=1
            filename = 'input.pyhtml'
            for f in glob(filename+'*'): os.path.exists(f) and os.remove(f)
            script = data['script1']
            args  = data['args1']
            input = data['input1']
            cachename = filename+'.cache'
            not_ok (cachename).exists()
            _test(filename, cachename, True, input, script, args)
            ok (cachename).exists()
            _test(filename, cachename, True, None, script, args)
            ## args=[], cache=1
            cachename = filename+'.cache'
            input = data['input2']  # re.sub(r'<\?py #@ARGS.*?\?>\n', '<?py #@ARGS ?>\n', input)
            script = data['script2']  # re.sub(r'#@ARGS.*?\n', '#@ARGS \n', cache)
            args  = data['args2']   # []
            time.sleep(1)
            #ok (cachename).exists()
            _test(filename, cachename, True, input, script, args)
            #ok (cachename).exists()
            _test(filename, cachename, True, None, script, args)
        finally:
            _remove_files(['input.pyhtml'])


    def _test_template_path(self, keys):
        data = EngineTest.testdata['test_template_path']
        basedir = 'test_templates'
        try:
            os.mkdir(basedir)
            os.mkdir(basedir + '/common')
            os.mkdir(basedir + '/user')
            d = { 'layout':keys[0], 'body':keys[1], 'footer':keys[2], }
            for key in ('layout', 'body', 'footer'):
                filename = '%s/common/%s.pyhtml' % (basedir, key)
                write_file(filename, data['common_'+key])
                if d[key] == 'user':
                    filename = '%s/user/%s.pyhtml' % (basedir, key)
                    write_file(filename, data['user_'+key])
            #
            path = [basedir+'/user', basedir+'/common']
            engine = tenjin.Engine(postfix='.pyhtml', path=path, layout=':layout')
            context = {'items':('AAA', 'BBB', 'CCC')}
            output = engine.render(':body', context)
            #
            expected = data['expected_' + '_'.join(keys)]
            ok (output) == expected
        finally:
            #os.removedirs(basedir)
            #pass
            for filename in glob('%s/*/*' % basedir):
                os.unlink(filename)
            for filename in glob('%s/*' % basedir):
                os.rmdir(filename)
            os.rmdir(basedir)

    def test_template_path_common_common_common(self):
        self._test_template_path(('common', 'common', 'common'))
    def test_template_path_user_common_common(self):
        self._test_template_path(('user',   'common', 'common'))
    def test_template_path_common_user_common(self):
        self._test_template_path(('common', 'user',   'common'))
    def test_template_path_user_user_common(self):
        self._test_template_path(('user',   'user',   'common'))
    def test_template_path_common_common_user(self):
        self._test_template_path(('common', 'common', 'user'))
    def test_template_path_user_common_user(self):
        self._test_template_path(('user',   'common', 'user'))
    def test_template_path_common_user_user(self):
        self._test_template_path(('common', 'user',   'user'))
    def test_template_path_user_user_user(self):
        self._test_template_path(('user',   'user',   'user'))


    def test_preprocessor(self):
        data = EngineTest.testdata['test_preprocessor']
        try:
            basenames = ('form', 'create', 'update', 'layout', )
            filenames = []
            for name in basenames:
                filename = 'prep_%s.pyhtml' % name
                filenames.append(filename)
                write_file(filename, data[name])
            engine = tenjin.Engine(prefix='prep_', postfix='.pyhtml', layout=':layout', preprocess=True)
            #
            context = {
                'title': 'Create',
                'action': 'create',
                'params': { 'state': 'NY' },
            }
            actual = engine.render(':create', context)  # 1st
            ok (actual) == data['expected1']
            context['params'] = {'state': 'xx'}
            actual = engine.render(':create', context)  # 2nd
            #ok (actual) == data['expected1']
            expected = data['expected1'].replace(r' checked="checked"', '')
            ok (actual) == expected
            #
            context = {
                'title': 'Update',
                'action': 'update',
                'params': { 'state': 'NY' },
            }
            actual = engine.render(':update', context)  # 1st
            ok (actual) == data['expected2']
            context['params'] = { 'state': 'xx' }
            actual = engine.render(':update', context)  # 2nd
            ok (actual) == data['expected2'] # not changed!
            #
            ok (engine.get_template(':form').script) == data['cache1']
            ok (engine.get_template(':create').script) == data['cache2']
            ok (engine.get_template(':layout').script) == data['cache3']
            ok (engine.get_template(':update').script) == data['cache4']
            #
        finally:
            _remove_files(filenames)


    def test_include_with_kwargs(self):
        data = EngineTest.testdata['test_include_with_kwargs']
        write_file('index.pyhtml', data['index_html'])
        write_file('sub.pyhtml', data['sub_html'])
        expected = data['expected']
        #
        try:
            engine = tenjin.Engine()
            context = {}
            output = engine.render('index.pyhtml', context)
            ok (output) == expected
        finally:
            _remove_files(['index', 'sub'])


    def test_add_template(self):
        if "template is added then it can be got by get_template()":
            input = """val=#{val}"""
            template = tenjin.Template('foo.pyhtml', input=input)
            engine = tenjin.Engine(postfix='.pyhtml')
            engine.add_template(template)
            ok (engine.get_template('foo.pyhtml')) == template
            ok (engine.get_template(':foo')) == template
        if "template is added then it should not create cache file":
            ok (engine.render(':foo', {'val': 'ABC'})) == 'val=ABC'
            not_ok ('foo.pyhtml').exists()


if __name__ == '__main__':
    run(EngineTest)
