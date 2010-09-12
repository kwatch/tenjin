###
### $Release: $
### $Copyright$
### $License$
###

from oktest import ok, not_ok, run
import sys, os, re, time, shutil
from testcase_helper import *
from oktest import *

import tenjin
from tenjin.helpers import *


## Python 2.6 warns that GAE SDK uses deprecated modules
def _suppress_warnings():
    if sys.version_info[0:2] >= (2, 6):
        import warnings
        warnings.filterwarnings('ignore', category=DeprecationWarning, message=r'the (md5|sha)')
_suppress_warnings()

## GAE_HOME
GAE_HOME = os.environ.get('GAE_HOME')
if GAE_HOME:
    if not os.path.exists(path):
        raise Exception("%r: $GAE_HOME not exist." % GAE_HOME)
    if not os.path.dir(path):
        raise Exception("%r: $GAE_HOME is not a directory." % GAE_HOME)
else:
    path = '/usr/local/google_appengine'
    if os.path.isdir(path):
        GAE_HOME = path

if not GAE_HOME:

    sys.stderr.write("###\n")
    sys.stderr.write("### WARNING:\n")
    sys.stderr.write("### Cannot find 'google_appengine' directory. Please specify $GAE_HOME environment variable.\n")
    sys.stderr.write("###\n")

else:

    ## add google's library path
    sys.path.insert(0, GAE_HOME)
    import dev_appserver
    dev_appserver.fix_sys_path()

    ## setup stubs
    def setup_gae_stubs():
        ## import stub classes
        import google.appengine.api.apiproxy_stub_map
        from google.appengine.api.apiproxy_stub_map       import APIProxyStubMap
        from google.appengine.api.memcache.memcache_stub  import MemcacheServiceStub
        ## API proxy
        apiproxy = APIProxyStubMap()
        google.appengine.api.apiproxy_stub_map.apiproxy = apiproxy
        ## dummy memcache service
        apiproxy.RegisterStub('memcache', MemcacheServiceStub())

    ##
    class GaeModuleTest(object):

        def do_with_file(self, func, filename, content):
            f = open(filename, 'w')
            try:
                f.write(content)
                f.close()
                func()
            finally:
                if os.path.exists(filename):
                    os.unlink(filename)

        def before(self):
            app_id = 'helloworld'
            ver_id = 'dev123.1'
            os.environ.setdefault('CURRENT_VERSION_ID', ver_id)
            setup_gae_stubs()

        def test_01_init(self):
            import tenjin
            ok (tenjin.Engine.cache).is_a(tenjin.MarshalCacheStorage)
            ok (tenjin.helpers.fragment_cache.store).is_a(tenjin.MemoryBaseStore)
            import tenjin.gae; tenjin.gae.init()
            if "called then change tenjin.Engine.cache to support GAE":
                ok (tenjin.Engine.cache).is_a(tenjin.gae.GaeMemcacheCacheStorage)
            if "called then change fragment cache store to support GAE":
                ok (tenjin.helpers.fragment_cache.store).is_a(tenjin.gae.GaeMemcacheStore)
            if "called then change fragment cache prefix to 'fragment.'":
                ok (tenjin.helpers.fragment_cache.prefix) == 'fragment.'
            if "caleed then use version id as memcache namespace":
                expected = 'dev123'
                ok (tenjin.Engine.cache.namespace) == expected
                ok (tenjin.helpers.fragment_cache.store.namespace) == expected

        def test_11_render(self):
            filename = "test_11_render.pyhtml"
            input = (
                "<ul>\n"
                "<?py for item in items: ?>\n"
                "  <li>${item}</li>\n"
                "<?py #endfor ?>\n"
                "</ul>\n"
            )
            context = { 'items': ('AAA', 'BBB', 'CCC') }
            output = (
                "<ul>\n"
                "  <li>AAA</li>\n"
                "  <li>BBB</li>\n"
                "  <li>CCC</li>\n"
                "</ul>\n"
            )
            script = (
                "_buf.extend(('''<ul>\\n''', ));\n"
                "for item in items:\n"
                "    _buf.extend(('''  <li>''', escape(to_str(item)), '''</li>\\n''', ));\n"
                "#endfor\n"
                "_buf.extend(('''</ul>\\n''', ));\n"
            )
            def func():
                engine = tenjin.Engine()
                actual = engine.render(filename, context)
                ok (actual) == output
                not_ok (filename + '.cache').exists()
                if "rendered then converted script is stored into memcache":
                    from google.appengine.api import memcache
                    key = os.path.abspath(filename) + '.cache'
                    obj = memcache.get(key, namespace='dev123')
                    ok (obj).is_a(dict)
                    keys = obj.keys()
                    keys.sort()
                    ok (keys) == ['args', 'script', 'timestamp']
                    ok (obj['script']) == script
                if "cached then version is used as namespace":
                    ok (memcache.get(key)) == None
                    ok (memcache.get(key, namespace='dev123')) != None
                if "cached once then it is possible to render even if file is removed":
                    os.unlink(filename)
                    not_ok (filename).exists()
                    ok (engine.render(filename, context)) == output
            self.do_with_file(func, filename, input)

        def test_21_fragment(self):
            filename = "test_21_fragment.pyhtml"
            input = (
                "<ul>\n"
                "<?py if not_cached('items/1', 1): ?>\n"
                "<?py     for item in items: ?>\n"
                "  <li>${item}</li>\n"
                "<?py     #endfor ?>\n"
                "<?py #endif ?>\n"
                "<?py echo_cached() ?>\n"
                "</ul>\n"
            )
            context = { 'items': ['AAA', 'BBB', 'CCC'] }
            fragment = (
                "  <li>AAA</li>\n"
                "  <li>BBB</li>\n"
                "  <li>CCC</li>\n"
            )
            output = "<ul>\n" + fragment + "</ul>\n"
            def func():
                engine = tenjin.Engine()
                actual = engine.render(filename, context)
                ok (actual) == output
                #
                from google.appengine.api import memcache
                key = 'fragment.items/1'
                if "rendered then fragment is cached into memcache":
                    ok (memcache.get(key, namespace='dev123')) == fragment
                if "rendered again within lifetime then fragment is not changed":
                    context['items'].append('XXX')
                    ok (engine.render(filename, context)) == output
                    ok (memcache.get(key, namespace='dev123')) == fragment
                if "rendered again after liftime passed then fragment is changed":
                    time.sleep(2)
                    fragment2 = fragment + "  <li>XXX</li>\n"
                    ok (engine.render(filename, context)) == "<ul>\n" + fragment2 + "</ul>\n"
                    ok (memcache.get(key, namespace='dev123')) == fragment2
            self.do_with_file(func, filename, input)


    if __name__ == '__main__':
        run()
