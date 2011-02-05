# -*- coding: utf-8 -*-
import sys, os, re, time, getopt, marshal, fnmatch
from StringIO import StringIO
from glob import glob
python3 = sys.version_info[0] == 3
if python3:
    xrange = range

webext = None

## global vars
encoding = None
mode     = 'class'  # 'class' or 'dict'
lang     = None
quiet    = None
template_dir = 'templates'
use_str  = False
no_str   = False
flag_escape = False


def read_file(filename):
    f = open(filename)
    try:
        return f.read()
    finally:
        f.close()

def write_file(filename, content):
    f = open(filename, 'w')
    try:
        f.write(content)
    finally:
        f.close()


class Entry(object):

    basename = None
    name     = None
    salt     = None
    encoding = None
    template_filename = None
    salts    = [None]

    def __init__(self, salt=None):
        self.salt = salt
        if salt:
            self.name = self.basename + '-' + salt
            self.execute = getattr(self, '_execute_'+salt)
        else:
            self.name = self.basename
            self.execute = getattr(self, '_execute')

    def available(self):
        return True

    def create_template(self, filename=None):
        global lang, encodin, mode
        ## create template content
        if filename is None: filename = self.template_filename
        filenames = ['_header.html', filename, '_footer.html']
        dir = template_dir
        content = ''.join([ open(dir+'/'+fname).read() for fname in filenames ])
        ## encoding
        if lang == 'ja' and encoding:
            s = content.decode(encoding)
            s = s.replace(u'Stock Prices', u'\u682a\u4fa1\u4e00\u89a7\u8868')
            if encoding == 'shift-jis':   charset = 'Shift_JIS'
            elif encoding == 'euc-jp':    charset = 'EUC-JP'
            else:                         charset = encoding
            s = s.replace(u'encoding="UTF-8"', u'encoding="%s"' % charset)
            s = s.replace(u'charset=UTF-8', u'charset=%s' % charset)
            content = s.encode(encoding)
        ## convert template
        content = self.convert_template(content)
        ## foo['name'] => foo.name
        if mode == 'class':
            content = re.sub(r"(\w+)\['(\w+)'\]", r"\1.\2", content)
        ## write template file
        open(filename, 'w').write(content)
        return content

    def convert_template(self, content):
        return content

    def load_library(cls):
        raise NotImplementedError("%s.load_library(): not implemented yet." % cls.__class__.__name__)
    load_library = classmethod(load_library)

    def class_setup(cls):
        ret = cls.load_library()
        return bool(ret)
    class_setup = classmethod(class_setup)

    def setup(self):
        self.create_template()

    def teardown(self):
        pass

    def execute(self, context, ntimes):
        raise NotImplementedError("%s.execute(): not implemented yet." % self.__class__.__name__)

    subclasses = []
    def register(cls, classobj):
        cls.subclasses.append(classobj)
    register = classmethod(register)


class TenjinEntry(Entry):

    basename = 'tenjin'
    template_filename = 'bench_tenjin.pyhtml'
    salts = [None, 'create', 'str', 'webext']

    def convert_template(self, content):
        if flag_escape:
            content = re.sub(r'#\{(.*?)\}', r'${\1}', content)
        return content

    def load_library(cls):
        global tenjin, escape, to_str, use_str
        if globals().get('tenjin'): return tenjin
        try:
            tenjin = import_module('tenjin')
            from tenjin.helpers import escape, to_str
            if use_str: to_str = str
        except ImportError:
            tenjin = None
        #
        global webext
        try:
            webext = import_module('webext')
        except ImportError:
            webext = None
        return tenjin

    load_library = classmethod(load_library)

    def setup(self):
        Entry.setup(self)
        cachename = self.template_filename + '.cache'
        if os.path.isfile(cachename):
            os.unlink(cachename)

    def available(self):
        global tenjin
        return tenjin and True or False

    def _execute_create(self, context, ntimes):
        filename = self.template_filename
        for i in xrange(ntimes):
            cache = tenjin.MarshalCacheStorage()
            engine = tenjin.Engine(cache=cache)
            output = engine.render(filename, context)
        return output

    def _execute(self, context, ntimes):
        filename = self.template_filename
        tostrfunc = None
        if  use_str: tostrfunc = 'str'
        elif no_str: tostrfunc = ''
        engine = tenjin.Engine(cache=True, tostrfunc=tostrfunc)
        for i in xrange(ntimes):
            output = engine.render(filename, context)
        return output

    def _execute_str(self, context, ntimes):
        """use str() instead of to_str()"""
        filename = self.template_filename
        engine = tenjin.Engine(cache=True, tostrfunc='str')
        for i in xrange(ntimes):
            output = engine.render(filename, context)
        return output

    def _execute_webext(self, context, ntimes):
        """use webext.to_str() and webext.escape_html() instead of tenjin's helper functions"""
        global webext, to_str, escape
        if not webext:
            print("(webext is not installed)")
            return False
        #
        _to_str, _escape = to_str, escape
        to_str, escape = webext.to_str, webext.escape_html
        try:
            filename = self.template_filename
            engine = tenjin.Engine()
            for i in xrange(ntimes):
                output = engine.render(filename, context)
        finally:
            to_str, escape = _to_str, _escape
        return output

    def _execute_nocache(self, context, ntimes):
        filename = self.template_filename
        for i in xrange(ntimes):
            engine = tenjin.Engine(cache=False)
            output = engine.render(filename, context)
        return output

    def _execute_convert(self, context, ntimes):
        global encoding
        filename = self.template_filename
        remove_file(filename + '.cache')
        for i in xrange(ntimes):
            template = tenjin.Template(filename, encoding=encoding)
            #if tostr_encoding:
            #    #globals()['to_str'] = tenjin.generate_to_str_func(tostr_encoding)
            #    context['to_str'] = tenjin.generate_to_str_func(tostr_encoding)
            #template = tenjin.Template(filename, encoding=tmpl_encoding)
        return template.script

    def _execute_tmpl(self, context, ntimes):
        global encoding
        filename = self.template_filename
        for i in xrange(ntimes):
            #if tostr_encoding:
            #    #globals()['to_str'] = tenjin.generate_to_str_func(encoding)
            #    context['to_str'] = tenjin.generate_to_str_func(tostr_encoding)
            #template = tenjin.Template(filename, encoding=tmpl_encoding)
            template = tenjin.Template(filename, encoding=encoding)
            output = template.render(context)
            #if tmpl_encoding and isinstance(output, unicode):
            #    output = output.encode(tmpl_encoding)
        return output

    def _execute_defun(self, context, ntimes):
        global encoding
        filename = self.template_filename
        #template = tenjin.Template(filename, escapefunc='tenjin.escape', tostrfunc='tenjin.to_str')
        #if tostr_encoding:
        #    #globals()['to_str'] = tenjin.generate_to_str_func(encoding)
        #    context['to_str'] = tenjin.generate_to_str_func(tostr_encoding)
        #template = tenjin.Template(filename, encoding=tmpl_encoding)
        template = tenjin.Template(filename, encoding=encoding)
        sb = []; sb.append('''\
def tmpl_tenjin_view(_context):
    _buf = []
    _tmpl_tenjin_view(_buf, _context)
    return ''.join(_buf)
def _tmpl_tenjin_view(_buf, _context):
''')
        #sb.append("    locals().update(_context)\n")
        for k in context:
            sb.append("    %s = _context['%s']\n" % (k, k))
        pat = re.compile(r'^', re.M)
        sb.append(pat.sub('    ', template.script)) ; sb.append("\n")
        defun_code = ''.join(sb)
        #sys.stderr.write("*** debug: defun_code=%s\n" % (defun_code))
        exec(defun_code, globals(), globals())
        for i in xrange(0, ntimes):
            output = tmpl_tenjin_view(context)
        return output

Entry.register(TenjinEntry)


class DjangoEntry(Entry):

    basename = 'django'
    template_filename = 'bench_django.html'
    salts = [None, 'create']

    def convert_template(self, content):
        if flag_escape:
            content = re.sub(r'\|safe ?\}\}', ' }}', content)
        return content

    def load_library(cls):
        global django
        if globals().get('django'): return
        try:
            django = import_module('django')
            import_module('django.conf')
            django.conf.settings.configure()
            import_module('django.template')
            import_module('django.template.defaultfilters')
            #def oddeven(value):   # usage: {% forloop.counter|oddeven %}
            #    if value % 2 == 0:
            #        return "even"
            #    else:
            #        return "odd"
            #django.template.defaultfilters.register.filter(oddeven)
        except ImportError:
            django = None
        return django
    load_library = classmethod(load_library)

    def available(self):
        global django
        return django and True or False

    def _execute_create(self, context, ntimes):
        filename = self.template_filename
        for i in xrange(ntimes):
            s = open(filename).read()
            #if encoding:
            #    s = s.decode(encoding).encode('utf-8')
            t = django.template.Template(s)
            c = django.template.Context(context)
            output = t.render(c)
            #if encoding:
            #    output = output.decode('utf-8').encode(encoding)
        return output

    def _execute(self, context, ntimes):
        filename = self.template_filename
        s = open(filename).read()
        #if encoding:
        #    s = s.decode(encoding).encode('utf-8')
        t = django.template.Template(s)
        c = django.template.Context(context)
        for i in xrange(ntimes):
            output = t.render(c)
            #if encoding:
            #    output = output.decode('utf-8').encode(encoding)
        return output

Entry.register(DjangoEntry)


class CheetahEntry(Entry):

    basename = 'cheetah'
    template_filename = 'bench_cheetah.tmpl'
    salts = [None, 'create']

    def convert_template(self, content):
        if encoding:
            content = ('#unicode %s\n' % encoding) + content
        if flag_escape:
            content = re.sub(r'>(\$\w+(\.\w+|\[.*?\])?)<', r'>$cgi.escape(str(\1))<', content)
            content = re.sub(r'"(\$\w+(\.\w+|\[.*?\])?)"', r'"$cgi.escape(str(\1))"', content)
            content = re.sub(r'/(\$\w+(\.\w+|\[.*?\])?)"', r'/$cgi.escape(str(\1))"', content)
            content = "#import cgi\n" + content
        return content

    def load_library(cls):
        global Cheetah, bench_cheetah
        if globals().get('Cheetah'): return
        try:
            import_module('Cheetah')
            if 'Cheetah' not in globals(): import Cheetah    # why?
            cls().create_template()  # create template
            filename = cls.template_filename
            compiled = filename.replace('.tmpl', 'py')
            do_with_report('compiling %s' % filename,
                           lambda: os.system('cheetah compile %s' % filename))
            bench_cheetah = import_module(filename.replace('.tmpl', ''))
        except ImportError:
            Cheetah = None
        return Cheetah
    load_library = classmethod(load_library)

    def available(self):
        global Cheetah
        return Cheetah and True or False

    def _execute_create(self, context, ntimes):
        filename = self.template_filename
        for i in xrange(ntimes):
            template = bench_cheetah.bench_cheetah()
            #for key, val in context.items():
            #    setattr(template, key, val)
            template.stocks = context['stocks']
            output = template.respond()
            #if encoding:
            #    output = output.encode(encoding)
            #for key in context.keys():
            #    delattr(template, key)
        return output

    def _execute(self, context, ntimes):
        filename = self.template_filename
        template = bench_cheetah.bench_cheetah()
        #for key, val in context.items():
        #    setattr(template, key, val)
        template.stocks = context['stocks']
        for i in xrange(ntimes):
            output = template.respond()
            #if encoding:
            #    output = output.encode(encoding)
        #for key in context.keys():
        #    delattr(template, key)
        return output

Entry.register(CheetahEntry)


#class MyghtyEntry(Entry):
#
#    basename = 'myghty'
#    template_filename = 'bench_myghty.myt'
#    salts = [None, 'create']
#
#    def convert_template(self, content):
#        global encoding
#        content = "<%args>\n    stocks\n</%args>\n" + content
#        if encoding:
#            content = ("# -*- coding: %s -*-\n" % encoding) + content
#        return content
##
#    def load_library(cls):
#        global myghty
#        if globals().get('myghty'): return
#        try:
#            myghty = import_module('myghty')
#            import_module('myghty.interp')
#        except ImportError:
#            myghty = None
#        return myghty
#    load_library = classmethod(load_library)
#
#    def available(self):
#        global myghty
#        return myghty and True or False
#
#    def _execute_create(self, context, ntimes):
#        filename = self.template_filename
#        _encoding = self.encoding or sys.getdefaultencoding()
#        for i in xrange(ntimes):
#            interpreter = myghty.interp.Interpreter(component_root='.', output_encoding=_encoding)
#            component = interpreter.make_component(open(filename).read())
#            buf = StringIO()
#            interpreter.execute(component, request_args=context, out_buffer=buf)
#            output = buf.getvalue()
#            buf.close()
#        return output
#
#    def _execute(self, context, ntimes):
#        filename = self.template_filename
#        _encoding = self.encoding or sys.getdefaultencoding()
#        interpreter = myghty.interp.Interpreter(component_root='.', output_encoding=_encoding)
#        component = interpreter.make_component(open(filename).read())
#        for i in xrange(ntimes):
#            buf = StringIO()
#            interpreter.execute(component, request_args=context, out_buffer=buf)
#            output = buf.getvalue()
#            buf.close()
#        return output
#
#Entry.register(MyghtyEntry)


class KidEntry(Entry):

    basename = 'kid'
    template_filename = 'bench_kid.kid'
    salts = [None, 'create']

    def convert_template(self, content):
        content = re.sub(r'<html(.*)>',
                         r'<html\1 xmlns:py="http://purl.org/kid/ns#">',
                         content)
        if flag_escape:
            pass
        return content

    def load_library(cls):
        global kid, encoding
        if globals().get('kid'): return
        try:
            kid = import_module('kid')
            #kid.enable_import()
            cls().create_template()
            filename = cls.template_filename
            if not encoding:
                do_with_report('compling %s ...' % filename,
                               lambda: kid.Template(filename))   # compile
        except ImportError:
            kid = None
        return kid
    load_library = classmethod(load_library)

    def available(self):
        global kid
        return kid and True or False

    def _execute_create(self, context, ntimes):
        filename = self.template_filename
        encoding = self.encoding
        for i in xrange(ntimes):
            if encoding:
                s = open(filename).read().decode(encoding).encode('utf-8')
                template = kid.Template(source=s, encoding=encoding)
            else:
                template = kid.Template(file=filename)
            for key, val in context.items():
                setattr(template, key, val)
            output = template.serialize(encoding=encoding)
            for key in context.keys():
                delattr(template, key)
        return output

    def _execute(self, context, ntimes):
        filename = self.template_filename
        encoding = self.encoding
        if encoding:
            s = open(filename).read().decode(encoding).encode('utf-8')
            template = kid.Template(source=s, encoding=encoding)
        else:
            template = kid.Template(file=filename)
        for key, val in context.items():
            setattr(template, key, val)
        for i in xrange(ntimes):
            output = template.serialize(encoding=encoding)
        for key in context.keys():
            delattr(template, key)
        return output

Entry.register(KidEntry)


class GenshiEntry(Entry):

    basename = 'genshi'
    template_filename = 'bench_genshi.html'
    salts = [None, 'create']

    def convert_template(self, content):
        content = re.sub(r'<html(.*)>',
                         r'<html\1 xmlns:py="http://genshi.edgewall.org/">',
                         content)
        if flag_escape:
            content = re.sub(r'py:content="Markup\((.*?)\)"', r'py:content="\1"', content)
        return content

    def load_library(cls):
        global genshi
        if globals().get('genshi'): return
        try:
            genshi = import_module('genshi.template')
        except ImportError:
            genshi = None
        return genshi
    load_library = classmethod(load_library)

    def available(self):
        global genshi
        return genshi and True or False

    def _execute_create(self, context, ntimes):
        filename = self.template_filename
        encoding = self.encoding
        for i in xrange(ntimes):
            loader = genshi.template.TemplateLoader('.', auto_reload=True)
            template = loader.load(filename)
            output = template.generate(**context).render('html', doctype='html')
            #if encoding:
            #    pass
        return output

    def _execute(self, context, ntimes):
        filename = self.template_filename
        encoding = self.encoding
        loader = genshi.template.TemplateLoader('.', auto_reload=True)
        template = loader.load(filename)
        for i in xrange(ntimes):
            output = template.generate(**context).render('html', doctype='html')
            #if encoding:
            #    pass
        return output

Entry.register(GenshiEntry)


class MakoEntry(Entry):

    basename = 'mako'
    template_filename = 'bench_mako.html'
    salts = [None, 'create', 'nocache']

    mako_module_dir = 'mako_modules'

    def convert_template(self, content):
        if flag_escape:
            content = re.sub(r'\$\{(.*?)\}', r'${\1|h}', content)
        return content

    def load_library(cls):
        global mako
        if globals().get('mako'): return
        try:
            mako = import_module('mako.template')
            import_module('mako.lookup')
            if not os.path.isdir(cls.mako_module_dir):
                os.mkdir(cls.mako_module_dir)
        except ImportError:
            mako = None
        return mako
    load_library = classmethod(load_library)

    def available(self):
        global mako
        return mako and True or False

    def _execute_create(self, context, ntimes):
        filename = self.template_filename
        mako_module_dir = self.mako_module_dir
        for i in xrange(ntimes):
            lookup = mako.lookup.TemplateLookup(directories=['.'], module_directory=mako_module_dir)
            template = lookup.get_template(filename)
            #if encoding:
            #    pass
            #output = template.render(**context)
            output = template.render(stocks=context['stocks'])
        return output

    def _execute(self, context, ntimes):
        filename = self.template_filename
        mako_module_dir = self.mako_module_dir
        lookup = mako.lookup.TemplateLookup(directories=['.'], module_directory=mako_module_dir)
        template = lookup.get_template(filename)
        #if encoding:
        #    pass
        for i in xrange(ntimes):
            #output = template.render(**context)
            output = template.render(stocks=context['stocks'])
        return output

    def _execute_nocache(self, context, ntimes):
        filename = self.template_filename
        mako_module_dir = self.mako_module_dir
        for i in xrange(ntimes):
            lookup = mako.lookup.TemplateLookup(directories=['.'])
            template = lookup.get_template(filename)
            #if encoding:
            #    pass
            #output = template.render(**context)
            output = template.render(stocks=context['stocks'])
        return output

Entry.register(MakoEntry)


class TempletorEntry(Entry):

    basename = 'templetor'
    template_filename = 'bench_templetor.html'
    salts = [None, 'create']

    def convert_template(self, content):
        content = "$def with (stocks)\n" + content
        if flag_escape:
            content = re.sub(r'\$:', r'$', content)
        return content

    def load_library(cls):
        global web
        if globals().get('web'): return
        try:
            web = import_module('web')
        except ImportError:
            web = None
        return web
    load_library = classmethod(load_library)

    def available(self):
        global web
        return web and True or False

    def _execute_create(self, context, ntimes):
        filename = self.template_filename
        for i in xrange(ntimes):
            render = web.template.render('.', cache=True)
            output = render.bench_templetor(context['stocks'])
        return str(output)

    def _execute(self, context, ntimes):
        filename = self.template_filename
        render = web.template.render('.', cache=True)
        for i in xrange(ntimes):
            output = render.bench_templetor(context['stocks'])
        return output

    def _execute_nocache(self, context, ntimes):
        filename = self.template_filename
        for i in xrange(ntimes):
            render = web.template.render('.', cache=False)
            output = render.bench_templetor(context['stocks'])
        return output

Entry.register(TempletorEntry)


class Jinja2Entry(Entry):

    basename = 'jinja2'
    template_filename = 'bench_jinja2.html'
    salts = [None, 'create']

    def convert_template(self, content):
        if flag_escape:
            content = re.sub(r'\}\}', '|e}}', content)
        return content

    def load_library(cls):
        global jinja2
        if globals().get('jinja2'): return
        try:
            jinja2 = import_module('jinja2')
        except ImportError:
            jinja2 = None
        return jinja2
    load_library = classmethod(load_library)

    def available(self):
        global jinja2
        return jinja2 and True or False

    def _execute_create(self, context, ntimes):
        filename = self.template_filename
        for i in xrange(ntimes):
            env = jinja2.Environment(loader=jinja2.FileSystemLoader(['.']))
            template = env.get_template(filename)
            output = template.render(context)
        return output

    def _execute(self, context, ntimes):
        filename = self.template_filename
        env = jinja2.Environment(loader=jinja2.FileSystemLoader(['.']))
        for i in xrange(ntimes):
            template = env.get_template(filename)
            output = template.render(context)
        return output

Entry.register(Jinja2Entry)


class PythonEntry(Entry):

    basename = 'python'
    template_filename = None
    salts = [ re.match('pythoncode/python_(.*)\.py', x).group(1)
                for x in glob('pythoncode/python_*.py') ]
    salts.sort()
    salts = []

    def create_template(cls, filename=None):
        pass
    create_template = classmethod(create_template)

    def load_library(cls):
        return True
    load_library = classmethod(load_library)

    def available(self):
        return True

    def _execute_(self, filename, context, ntimes, _buf = None):
        script = read_file(filename)
        code = compile(script, filename, 'exec')
        from tenjin.helpers import to_str, escape
        global use_str
        if use_str: to_str = str
        global_vars = globals()
        for i in xrange(ntimes):
            local_vars = { 'to_str': to_str, 'stocks': context['stocks'], '_buf': _buf, 'escape': escape }
            exec(code, global_vars, local_vars)
            output = local_vars.get('output')
        return output or True

    def _execute_mmap_str(self, context, ntimes):
        filename = 'pythoncode/python_mmap_str.py'
        import mmap
        _buf = mmap.mmap(-1, 2*1024*1024);
        return self._execute_(filename, context, ntimes, _buf)

for filename in glob('pythoncode/python_*.py'):
    name = re.match('pythoncode/python_(.*).py', filename).group(1)
    method_name = "_execute_%s" % name
    if hasattr(PythonEntry, method_name): continue
    def method_func(self, context, ntimes, _filename=filename):
        return self._execute_(_filename, context, ntimes)
    setattr(PythonEntry, method_name, method_func)

Entry.register(PythonEntry)


## ----------------------------------------


## helper methods
def msg(message):
    global quiet
    if not quiet:
        sys.stdout.write(message)
        sys.stdout.flush()

def do_with_report(title, do_func):
    msg(title)
    msg(' ... ')
    start_t = time.time()
    ret = do_func()
    end_t = time.time()
    msg('done. (%f sec)\n' % (end_t - start_t))
    return ret

def import_module(name):
    try:
        return do_with_report('import %s' % name, lambda: __import__(name))
    except ImportError:
        ex = sys.exc_info()[1]
        msg("\n")
        msg("*** module %s not found.\n" % name)
        raise ex

def remove_file(*filenames):
    for filename in filenames:
        if os.path.isfile(filename):
            os.unlink(filename)


## ----------------------------------------


def main(ntimes=1000):
    global encoding, mode, quiet, flag_escape

    ## parse options
    try:
        optlist, targets = getopt.getopt(sys.argv[1:], "hpf:n:t:x:Aqm:ek:l:C", ['str', 'nostr'])
        options = dict([(key[1:], val == '' and True or val) for key, val in optlist])
    except Exception:
        ex = sys.exc_info()[1]
        sys.stderr.write(str(ex) + "\n")
        sys.exit(1)
    #sys.stderr.write("*** debug: options=%s, targets=%s\n" % (repr(options), repr(targets)))

    ## help
    script = os.path.basename(sys.argv[0])
    if options.get('h'):
        print_help(script, ntimes, mode)
        sys.exit(0)

    ## set parameters
    ntimes = int(options.get('n', ntimes))
    quiet = options.get('q', quiet)
    mode  = options.get('m', mode)
    if mode not in ['class', 'dict']:
        sys.stderr.write("-m %s: 'dict' or 'class' expected." % mode)
        sys.exit(1)
    lang = options.get('l')
    encoding  = None
    #tostr_encoding = None   # for PyTenjin
    #tmpl_encoding  = None   # for PyTenjin
    if options.get('e'):
        flag_escape = True
    if options.get('k'):
        encoding       = options['k']
        #tostr_encoding = encoding
        #tmpl_encoding  = None
        #to_str = tenjin.generate_to_str_func(tostr_encoding)
    if options.get('-str'):
        global use_str
        use_str = True
    if options.get('-nostr'):
        global no_str
        no_str = True
    ## default targets
    target_list = []
    for cls in Entry.subclasses:
        basename = cls.basename
        for salt in cls.salts:
            target = salt and basename+'-'+salt or basename
            target_list.append(target)
    ##
    targets = filter_targets(targets, target_list, options.get('x'))
    entries = get_entries(targets)
    datafile = options.get('f')
    context = load_context_data(datafile)
    if options.get('C'):
        context = _convert(context)
    print_output = options.get('p')
    execute_benchmark(entries, context, ntimes, print_output)


def _convert(val):
    if isinstance(val, list):
        i = 0
        n = len(val)
        while i < n:
            val[i] = _convert(val[i])
            i += 1
    elif isinstance(val, dict):
        for k in val.keys():
            val[k] = _convert(val[k])
    elif val is None:
        val = ""
    elif hasattr(val, '__dict__'):
        _convert(val.__dict__)
    else:
        val = str(val)
    return val


def print_help(script, ntimes, mode):
    print "Usage: python %s [..options..] [..targets..]" % script
    print "  -h          :  help"
    print "  -p          :  print output"
    print "  -e          :  escape html"
    print "  -f file     :  datafile ('*.py' or '*.yaml')"
    print "  -n N        :  loop N times (default %d)" % ntimes
    print "  -x exclude  :  excluded target name"
    print "  -q          :  quiet mode"
    print "  -m mode     :  'class' or 'dict' (default '%s')" % mode
    #print "  -k encodng  :  encoding (default None)"
    #print "  -l lang     :  language ('ja') (default None)"
    print "  -C          :  convert numbers in context data into string in advance"
    print "  --str       :  use 'str()' instead of 'tenjin.helper.to_str()'"


def filter_targets(targets, target_list, excludes):
    if targets:
        L = []
        for t in targets:
            if t.find('*') >= 0:
                pattern = t
                L.extend(fnmatch.filter(target_list, pattern))
            else:
                L.append(t)
        targets = L
    else:
        targets = target_list[:]
    if excludes:
        for exclude in excludes.split(','):
            if exclude in targets:
                targets.remove(exclude)
            elif exclude.find('*'):
                pattern = exclude
                for t in fnmatch.filter(target_list, pattern):
                    if t in targets:
                        targets.remove(t)
    return targets
    #sys.stderr.write("*** debug: ntimes=%s, targets=%s\n" % (repr(ntimes), repr(targets)))


def load_context_data(datafile):
    global mode, lang
    ## context data
    #msg("*** loading context data...\n")
    #if not datafile:
    #    if   mode == 'dict':   datafile = 'bench_context.yaml'
    #    elif mode == 'class':  datafile = 'bench_context.py'
    #    else: assert False, "** unreachable"
    #if datafile.endswith('.py'):
    #    exec(open(datafile).read(), globals(), context)
    #elif datafile.endswith('.yaml') or datafile.endswith('.yml'):
    #    import yaml
    #    s = open(datafile).read()
    #    if encoding:
    #        s = s.decode(encoding)
    #    context = yaml.load(s)
    #else:
    #    raise "-f %s: invalid datafile type" % datafile
    #sys.stderr.write("*** debug: context=%s\n" % (repr(context)))
    #return context
    if not datafile: datafile = 'bench_context.py'
    if lang: datafile = re.sub(r'(\.\w+)', r'_%s\1' % lang, datafile)
    msg("*** loading context data (file=%s)...\n" % datafile)
    s = read_file(datafile)
    if encoding: s = s.decode(encoding)
    context = {}
    exec(s, globals(), context)
    #if 'items' in context and 'items2' in context:
    #    k = mode == 'dict' and 'items' or 'items2'
    #    context['stocks'] = context[k]
    context['stocks'] = context['items']
    return context


def get_entries(targets, **kwargs):
    entries = []
    classtable = {}
    for target in targets:
        L = re.split(r'[-_]', target, 1)
        base = L[0]
        salt = len(L) > 1 and L[1] or None
        if base in classtable:
            classobj = classtable.get(base)
        else:
            classname = base.capitalize() + 'Entry'
            classobj = globals().get(classname)
            if not classobj:
                raise Exception("%s: invalid target name." % target)
            ret = classobj.class_setup(**kwargs)
            if not ret: classobj = None
            classtable[base] = classobj
        if classobj:
            entry = classobj(salt)
            entries.append(entry)
    return entries


def execute_benchmark(entries, context, ntimes, print_output):

    ## benchmark
    msg('*** start benchmark\n')

    print  "*** ntimes=%d" % ntimes
    #print "                   target           utime     stime     total      real"
    print  "                                    utime     stime     total      real"

    for entry in entries:
        print "%-30s " % entry.name,
        sys.stdout.flush()

        ## setup
        entry.setup()

        ## start time
        start_t = time.time()
        t1 = os.times()

        ## call benchmark function
        output = entry.execute(context, ntimes)
        done = output and True or False

        ## end time
        t2 = os.times()
        end_t = time.time()

        ## teardown
        entry.teardown()

        ## result
        if done:
            utime = t2[0]-t1[0]
            stime = t2[1]-t1[1]
            #total = t2[4]-t1[4]
            total = utime + stime
            real  = end_t-start_t
            #print "%-24s  %9.4f %9.4f %9.4f %9.4f" % (target, utime, stime, total, real)
            print         "%9.4f %9.4f %9.4f %9.4f" % (        utime, stime, total, real)
        elif output is None:
            #print "%-24s     (module not installed)" % target
            print         "   (module not installed)"
        else:
            assert output is False
            pass

        ## print output
        if print_output:
            if isinstance(output, basestring):
                fname = '%s.result' % entry.name
                open(fname, 'w').write(output)
                msg('*** output created: %s\n' % fname)


if __name__ == '__main__':
    main()
