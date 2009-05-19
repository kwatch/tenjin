import sys, os, re, time, getopt, marshal, fnmatch
from StringIO import StringIO


## defaults
ntimes = 1000
quiet  = False
mode   = 'class'   # 'class' or 'dict'
targets_default = "\
tenjin-pycodecache tenjin-bytecodecache tenjin-nocache tenjin-reuse \
django django-reuse \
cheetah cheetah-reuse \
myghty myghty-reuse \
kid kid-reuse \
mako mako-reuse mako-module".split(' ')
targets_all = "\
tenjin-tmpl tenjin-pycodecache tenjin-bytecodecache tenjin-nocache tenjin-reuse tenjin-defun \
django django-reuse \
cheetah cheetah-reuse \
myghty myghty-reuse \
kid kid-reuse \
mako mako-reuse mako-filecache".split(' ')


## helper methods
def msg(message):
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

def is_required(name):
    global targets
    for t in targets:
        if t.startswith(name):
            return True
    return False

def has_metachar(s):
    return re.search(r'[*?]', s) is not None


## parse options
try:
    optlist, targets = getopt.getopt(sys.argv[1:], "hpf:n:t:x:Aqm:")
    options = dict([(key[1:], val == '' and True or val) for key, val in optlist])
except Exception:
    ex = sys.exc_info()[1]
    sys.stderr.write(str(ex) + "\n")
    sys.exit(1)
#sys.stderr.write("*** debug: options=%s, targets=%s\n" % (repr(options), repr(targets)))


## help
script = os.path.basename(sys.argv[0])
if options.get('h'):
    print "Usage: python %s [..options..] [..targets..]" % script
    print "  -h         :  help"
    print "  -p         :  print output"
    print "  -f file    :  datafile ('*.py' or '*.yaml')"
    print "  -n N       :  loop N times (default %d)" % ntimes
    print "  -x exclude :  excluded target name"
    print "  -q         :  quiet mode"
    print "  -m mode    :  'class' or 'dict' (default '%s')" % mode
    sys.exit(0)


## set parameters
ntimes = int(options.get('n', ntimes))
quiet = options.get('q', quiet)
mode  = options.get('m', mode)
if mode not in ['class', 'dict']:
    sys.stderr.write("-m %s: 'dict' or 'class' expected." % mode)
    sys.exit(1)
##
target_list = options.get('A') and targets_all or targets_default
if targets:
    lst = []
    for t in targets:
        if t.find('*') >= 0:
            pattern = t
            lst.extend(fnmatch.filter(target_list, pattern))
        else:
            lst.append(t)
    targets = lst
else:
    targets = target_list[:]
excludes = options.get('x')
if excludes:
    for exclude in excludes.split(','):
        if exclude in targets:
            targets.remove(exclude)
        elif exclude.find('*'):
            pattern = exclude
            for t in fnmatch.filter(targets_all, pattern):
                if t in targets:
                    targets.remove(t)
#sys.stderr.write("*** debug: ntimes=%s, targets=%s\n" % (repr(ntimes), repr(targets)))


## context data
msg("*** loading context data...\n")
datafile = options.get('f')
if not datafile:
    if mode == 'dict':
        datafile = 'bench_context.yaml'
    elif mode == 'class':
        datafile = 'bench_context.py'
    else:
        unreachable
context = {}
if datafile.endswith('.py'):
    exec(open(datafile).read(), globals(), context)
elif datafile.endswith('.yaml') or datafile.endswith('.yml'):
    import yaml
    context = yaml.load(open(datafile))
else:
    raise "-f %s: invalid datafile type" % datafile
#sys.stderr.write("*** debug: context=%s\n" % (repr(context)))


## generate templates
template_names = {
    'tenjin':   'bench_tenjin.pyhtml',
    'django':  'bench_django.html',
    'cheetah': 'bench_cheetah.tmpl',
    'myghty':  'bench_myghty.myt',
    'kid':     'bench_kid.kid',
    'mako':    'bench_mako.html',
}
msg('*** generate templates...\n')
header = open('templates/_header.html').read()
footer = open('templates/_footer.html').read()
var = None
for key, filename in template_names.items():
    body = open('templates/' + filename).read()
    if mode == 'class':
        body = re.sub(r"(\w+)\['(\w+)'\]", r"\1.\2", body)
    s = header + body + footer
    if key == 'kid':
        s = re.sub(r'<html(.*)>', r'<html\1 xmlns:py="http://purl.org/kid/ns#">', s)
    elif key == 'myghty':
        s = "<%args>\n    list\n</%args>\n" + s
    #elif tmplname.endswith('_mako'):
    #    s = '<%page cached="True" />\n' + s
    open(filename, 'w').write(s)


## preparations
msg('*** preparations...\n')

if is_required('tenjin'):
    try:
        tenjin = import_module('tenjin')
        from tenjin.html import escape, to_str
    except ImportError:
        tenjin = None

if is_required('django'):
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
        ex = sys.exc_info()[1]
        django = None

if is_required('cheetah'):
    template_name = template_names['cheetah']
    try:
        compiled = template_name.replace('.tmpl', '.py')
        do_with_report('compiling %s' % template_name,
                       lambda: os.system('cheetah compile %s' % template_name))
        bench_cheetah = import_module(template_name.replace('.tmpl', ''))
        bench_cheetah2 = bench_cheetah
        cheetah = True
    except ImportError:
        cheetah = None

if is_required('myghty'):
    try:
        myghty = import_module('myghty')
        myghty.interp = import_module('myghty.interp').interp
    except ImportError:
        myghty = None

if is_required('kid'):
    try:
        kid = import_module('kid')
        #kid.enable_import()
        template_name = template_names['kid']
        do_with_report('compling %s ...' % template_name,
                       lambda: kid.Template(template_name))   # compile
        #t = kid.Template(tmpl_kid)   # compile
    except ImportError:
        kid = None

if is_required('mako'):
    try:
        mako = import_module('mako')
        import_module('mako.template')
        #import mako.template
        context2 = context.copy()
        context2['items'] = context2.pop('list')
    except ImportError:
        mako = None


## benchmark functions

def benchmark_tenjin_convert(template_name, context, ntimes):
    if tenjin:
        for i in xrange(0, ntimes):
            template = tenjin.Template(template_name)
        return True
    return False

def benchmark_tenjin_tmpl(template_name, context, ntimes):
    if tenjin:
        for i in xrange(0, ntimes):
            template = tenjin.Template(template_name)
            output = template.evaluate(context)
        return True
    return False

def benchmark_tenjin_pycodecache(template_name, context, ntimes):
    if tenjin:
        for i in xrange(0, ntimes):
            manager = tenjin.TemplateManager(cache=None)
            output = manager.evaluate(template_name, context)
        return True
    return False

def benchmark_tenjin_bytecodecache(template_name, context, ntimes):
    if tenjin:
        for i in xrange(0, ntimes):
            manager = tenjin.TemplateManager(cache=True)
            output = manager.evaluate(template_name, context)
        return True
    return False

def benchmark_tenjin_nocache(template_name, context, ntimes):
    if tenjin:
        for i in xrange(0, ntimes):
            manager = tenjin.TemplateManager(cache=False)
            output = manager.evaluate(template_name, context)
        return True
    return False

def benchmark_tenjin_reuse(template_name, context, ntimes):
    if tenjin:
        manager = tenjin.TemplateManager(cache=False)
        for i in xrange(0, ntimes):
            output = manager.evaluate(template_name, context)
        return True
    return False

def benchmark_tenjin_defun(template_name, context, ntimes):
    if tenjin:
        #template = tenjin.Template(template_name, escapefunc='tenjin.escape', tostrfunc='tenjin.to_str')
        template = tenjin.Template(template_name)
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
        sb.append(pat.sub('    ', template.pycode)) ; sb.append("\n")
        defun_code = ''.join(sb)
        #sys.stderr.write("*** debug: defun_code=%s\n" % (defun_code))
        exec(defun_code)
        for i in xrange(0, ntimes):
            output = tmpl_tenjin_view(context)
        return True
    return False

def benchmark_django(template_name, context, ntimes):
    if django:
        for i in xrange(0, ntimes):
            s = open(template_name).read()
            t = django.template.Template(s)
            c = django.template.Context(context)
            output = t.render(c)
        return True
    return False

def benchmark_django_reuse(template_name, context, ntimes):
    if django:
        s = open(template_name).read()
        t = django.template.Template(s)
        c = django.template.Context(context)
        for i in xrange(0, ntimes):
            output = t.render(c)
        return True
    return False

def benchmark_cheetah(template_name, context, ntimes):
    if cheetah:
        for i in xrange(0, ntimes):
            template = bench_cheetah.bench_cheetah()
            for key, val in context.items():
                setattr(template, key, val)
            output = template.respond()
        return True
    return False

def benchmark_cheetah_reuse(template_name, context, ntimes):
    if cheetah:
        template = bench_cheetah.bench_cheetah()
        for key, val in context.items():
            setattr(template, key, val)
        for i in xrange(0, ntimes):
            output = template.respond()
        #for key in context.keys():
        #    delattr(template, key)
        return True
    return False

def benchmark_myghty(template_name, context, ntimes):
    if myghty:
        for i in xrange(0, ntimes):
            interpreter = myghty.interp.Interpreter(component_root='.')
            component = interpreter.make_component(open(template_name).read())
            buf = StringIO()
            interpreter.execute(component, request_args=context, out_buffer=buf)
        output = buf.getvalue()
        buf.close()
        return True
    return False

def benchmark_myghty_reuse(template_name, context, ntimes):
    if myghty:
        interpreter = myghty.interp.Interpreter(component_root='.')
        component = interpreter.make_component(open(template_name).read())
        for i in xrange(0, ntimes):
            buf = StringIO()
            interpreter.execute(component, request_args=context, out_buffer=buf)
        output = buf.getvalue()
        buf.close()
        return True
    return False

def benchmark_kid(template_name, context, ntimes):
    if kid:
        for i in xrange(0, ntimes):
            template = kid.Template(file=template_name)
            for key, val in context.items():
                setattr(template, key, val)
            output = template.serialize()
            for key in context.keys():
                delattr(template, key)
        return True
    return False

def benchmark_kid_reuse(template_name, context, ntimes):
    if kid:
        template = kid.Template(file=template_name)
        for key, val in context.items():
            setattr(template, key, val)
        for i in xrange(0, ntimes):
            output = template.serialize()
        for key in context.keys():
            delattr(template, key)
        return True
    return False

def benchmark_mako(template_name, context, ntimes):
    if mako:
        context2 = context.copy()
        context2['items'] = context2.pop('list')
        for i in xrange(0, ntimes):
            template = mako.template.Template(filename=template_name)
            #output = template.render(items=context2['items'])
            output = template.render(**context2)
        return True
    return False

def benchmark_mako_reuse(template_name, context, ntimes):
    if mako:
        context2 = context.copy()
        context2['items'] = context2.pop('list')
        template = mako.template.Template(filename=template_name)
        for i in xrange(0, ntimes):
            #output = template.render(items=context2['items'])
            output = template.render(**context2)
        return True
    return False

def benchmark_mako_filecache(template_name, context, ntimes):
    if mako:
        context2 = context.copy()
        context2['items'] = context2.pop('list')
        s = open(template_name).read()
        s = s + '<%page cached="True" />\n'
        open(template_name, 'w').write(s)
        for i in xrange(0, ntimes):
            template = mako.template.Template(filename=template_name, cache_dir='.', cache_type='file')
            #output = template.render(items=context2['items'])
            output = template.render(**context2)
        return True
    return False

def benchmark_mako_module(template_name, context, ntimes):
    if mako:
        from mako_helper import *
        for i in xrange(0, ntimes):
            output = render_mako_template(template_name, **context2)
        return True
    return False


## benchmark function table
names = globals().keys()
func_table = {}
for name in names:
    if name.startswith('benchmark_'):
        func = globals()[name]
        if callable(func):
            name = name[len('benchmark_'):]
            func_table[name] = func
            func_table[re.sub(r'_', '-', name)] = func


## benchmark
msg('*** start benchmark\n')

if options.get('p'):
    ntimes = 1
else:
    print  "*** ntimes=%d" % ntimes
    #print "             target        utime      stime      total       real"
    print  "                           utime      stime      total       real"

for target in targets:
    print "%-20s " % target,
    sys.stdout.flush()

    ## start time
    start_t = time.time()
    t1 = os.times()

    ## call benchmark function
    func = func_table[target]
    key  = re.split(r'[-_]', target)[0]
    done = False
    if func:
        done = func.__call__(template_names[key], context, ntimes)
    else:
        sys.stderr.write("*** %s: invalid target.\n" % target)
        sys.exit(1)

    ## end time
    t2 = os.times()
    end_t = time.time()

    ## print output
    if options.get('p'):
        open('%s.result' % target, 'w').write(output)
        print 'created: %s.result' % target
        continue

    ## result
    elif done:
        utime = t2[0]-t1[0]
        stime = t2[1]-t1[1]
        #total = t2[4]-t1[4]
        total = utime + stime
        real  = end_t-start_t
        #print "%-20s  %10.5f %10.5f %10.5f %10.5f" % (target, utime, stime, total, real)
        print         "%10.5f %10.5f %10.5f %10.5f" % (        utime, stime, total, real)
    else:
        #print "%-20s     (module not installed)" % target
        print         "   (module not installed)"

