from __future__ import with_statement

import sys, os, re
from glob import glob
from kook.utils import glob2

#def to_strong(s):
#    s = re.sub(r'\{\{\*', '<strong>', s)
#    s = re.sub(r'\*\}\}', '</strong>', s)
#    return s
#
#def to_unstrong(str):
#    s = re.sub(r'\{\{\*', '', s)
#    s = re.sub(r'\*\}\}', '', s)
#    return s
#
#def pre_to_console(s):
#    s = re.sub('<pre class="literal-block">\n\\$', '<pre class="console">\n$', s)
#    return s
#
#def pre_to_file(s):
#    s = re.sub('<pre class="literal-block">\n', '<pre class="file">\n', s)
#    return s


tagfile  = prop('tagfile', 'html-css')

#dir = 'data'
testdir  = '../test'
datadir  = testdir + '/data'
#title   = "Tenjin User's Guide"
#stylesheet = 'html4css1.css'
stylesheet = 'docstyle.css'
#rstdir   = '/Library/Frameworks/Python.framework/Versions/2.4/bin'
#rst2html = rstdir+'/rst2html.py'
#rst2html_opts = 'rst2html_opts', '--link-stylesheet --no-xml-declaration --no-source-link --no-toc-backlinks --language=en --stylesheet="%s" --title="%s"' % (stylesheet, title)  #--strip-comments
tidy_opts = prop('tidy_opts', '-q -i -wrap 9999 --hide-comments yes')

#users_guide_eruby = 'users-guide.eruby'
original_docdir = re.sub(r'/tenjin/.*$', r'/tenjin/common/doc/', os.getcwd())
#users_guide_eruby = original_docdir + 'users-guide.eruby'
users_guide_eruby = original_docdir + 'tutorial.txt.eruby'
examples_eruby    = original_docdir + 'examples.eruby'
kook_default_product = 'all'
testfiles = ['test_users_guide.py']
basenames = ['users-guide', 'examples']
textfiles = [ x+'.txt' for x in basenames]
htmlfiles = [ x+'.html' for x in basenames]


@recipe
@ingreds('doc', 'test')
def task_all(c):
    pass


@recipe
@ingreds(htmlfiles, stylesheet)
def task_doc(c):
    """generate *.html"""
    pass


@recipe
@product(stylesheet)
@ingreds(original_docdir + stylesheet)
def file_css(c):
    """generate *.css"""
    cp(c.ingred, c.product)


#@product('users-guide.html')
#@ingreds('users-guide.txt', 'retrieve')
#@byprods('users-guide.toc.html')
#def file_users_guide_html(c):
#    system(c%'kwaser -t $(tagfile) -T $(ingred) > $(byprod)')
#    system(c%'kwaser -t $(tagfile)    $(ingred) > $(product)')
#    rm(c.byproducts)


#@product('users-guide.html')
#@ingreds('users-guide.rst')
#@byprods('users-guide.tmp')
#def file_users_guide_html(c):
#    system_f(c%'$(rst2html) $(rst2html_opts) $(ingreds) 2>&1 > $(byprod)')
#    s = open(c.byprod).read()
#    s = to_string(s)
#    s = pre_to_console(s)
#    s = pre_to_file(s)
#    open(c.byprod, 'w').write(s)
#    system_f(c%'tidy $(tidy_opts) $(byprod) > $(product)')
#    rm(c.byprod)

@recipe
@product('*.html')
@ingreds('$(1).txt')
@byprods('$(1).toc.html')
def file_html(c):
    system(c%'kwaser -t $(tagfile) -T $(ingred) > $(byprod)')
    system(c%'kwaser -t $(tagfile)    $(ingred) > $(product)')
    system_f(c%'tidy -i -w 9999 -utf8 -m -q $(product)')
    repl = (
      (re.compile(r'^  <meta name="generator" content="HTML Tidy .*?\n', re.M), ''),
      (re.compile(r'^  <meta http-equiv="Content-Type" content="text/html">\n\n?', re.M),
       '  <meta http-equiv="Content-Type" content="text/html;charset=utf-8">\n'),
      (r'<p>\.\+NOTE:</p>', '<div class="note"><span class="caption">NOTE:</span>'),
      (r'<p>\.\-NOTE:</p>', '</div>'),
      (r'<p>\.\+TIPS:</p>', '<div class="tips"><span class="caption">TIPS:</span>'),
      (r'<p>\.\-TIPS:</p>', '</div>'),
    )
    edit(c.product, by=repl)

@recipe
@product('*.txt')
@ingreds(original_docdir + '$(1).eruby')
#@ingreds('$(1).eruby', if_exists(original_docdir + '/$(1).eruby')
def file_txt(c):
    """create *.txt from *.eruby and retrieve testdata from *.txt"""
    #if os.path.exists(c.ingreds[1]):
    #    cp(c.ingreds[1], c.ingred)
    os.environ['RUBYLIB'] = ''
    system(c%"erubis -E PercentLine -c '@lang=%q|python|' -p '\\[% %\\]' $(ingred) > $(product)");
    #
    name = re.sub(r'\.txt$', '', c.product.replace('-', '_'))
    datadir = testdir + '/data/' + name
    if os.path.exists(datadir):
        rm_rf(datadir + '/*')
    else:
        mkdir(datadir)
    system(c%"which retrieve");
    system(c%"retrieve -Fd $(datadir) $(product)");
    pat = datadir + '/*.result2'
    filenames = glob(datadir + '/*.result2')
    for filename in filenames:
        content = open(filename).read()
        os.unlink(filename)
        rexp = re.compile(r'^\$ ', re.M)
        contents = rexp.split(content)
        i = 0
        for cont in contents:
            if not cont: continue
            i += 1
            fname = re.sub(r'\.result2$', '%s.result' % i, filename)
            open(fname, 'w').write('$ ' + cont)
    #
    if name == 'faq':
        cp('../misc/my_template.py', datadir)


@recipe
@ingreds(testdir + '/test_users_guide.py',
         testdir + '/test_examples.py')
def task_create_test(c):
    """create test script"""
    pass


@recipe
def task_clean(c):
    rm_rf('*.toc.html', 'test.log', '*.pyc')


@recipe
@ingreds('test_users_guide', 'test_examples')
def task_test(c):
    pass


@recipe
@ingreds(testdir+'/test_users_guide.py', 'users-guide.txt')
def task_test_users_guide(c):
    name = re.sub(r'^test_', '', c.product)
    with chdir(testdir) as d:
        system(c%'python $(ingred)')


@recipe
@ingreds(testdir+'/test_examples.py', 'examples.txt')
def task_test_examples(c):
    task_test_users_guide(c)


@recipe
@product(testdir + '/test_users_guide.py')
@ingreds(testdir + '/test_users-guide.py')
def file_test_users_guide_py(c):
    mv(c.ingred, c.product)
    #mv("data/users-guide", "data/users_guide")


@recipe
@product(testdir+'/test_users-guide.py')
@ingreds('users-guide.txt')
def file_test_users_guide_py(c):
    ##
    CWD = os.getcwd()
    DIR = '%s/data/users_guide' % testdir
    os.chdir(DIR)
    try:
        testnames = glob('test_*')
        paths = [ x for x in glob('test_*') if re.search(r'test_\d+', x) ]
        fnames = {}
        for path in paths:
            d = {}
            for fpath in glob2(path + '/**/*'):
                if os.path.isfile(fpath):
                    fname = fpath[len(path)+1:]
                    fnames[fname] = fpath
                    d[fname] = True
            for base, src in fnames.items():
                if base not in d:
                    dest = path + '/' + base
                    if not os.path.exists(os.path.dirname(dest)):
                        #mkdir_p(os.path.dirname(dest))
                        os.mkdir(os.path.dirname(dest))
                    #cp(src, dest)
                    open(dest, 'w').write(open(src).read())
    finally:
        os.chdir(CWD)
    s = _create_users_guide_test_py(testnames)
    open(c.product, 'w').write(s)


def _create_users_guide_test_py(testnames):
    buf = []
    buf.append(r"""
###
### auto generated by ../doc/Kookbook.py
###

import sys, os, re
from glob import glob
from oktest import ok, run

python3 = sys.version_info[0] == 3
PYPY    = hasattr(sys, 'pypy_version_info')
JYTHON  = hasattr(sys, 'JYTHON_JAR')

try:    # Python 2.6 or later
    from subprocess import Popen, PIPE
    def _popen3(command):
        p = Popen(command, shell=True, close_fds=True,
                  stdin=PIPE, stdout=PIPE, stderr=PIPE)
        t = (p.stdin, p.stdout, p.stderr)
        return (p.stdin, p.stdout, p.stderr)
except ImportError:
    def _popen3(command):
        return os.popen3(command)


class UsersGuideTest(object):

    DIR = os.path.dirname(os.path.abspath(__file__)) + '/data/users_guide'
    CWD = os.getcwd()

    def before(self):
        #sys.stdout.write('\n** test_%s: (' % self.__name__)
        sys.stdout.write(' (')
        os.chdir(self.DIR + '/test_' + self.__name__)
        for x in glob('*.cache') + glob('views/*.cache'):
            os.unlink(x)
        if self.__name__ == 'flexibleindent':
            for parent_dir in ['..', '../..', '../../..']:
                fname = parent_dir + '/my_template.py'
                if os.path.isfile(fname):
                    import shutil
                    shutil.copy(fname, 'my_template.py')
                    break
        if PYPY:
            if self.__name__ == 'syntaxerr':
                s = (
                    "$ pytenjin -z syntaxerr.pyhtml\n"
                    "syntaxerr.pyhtml:5:8: invalid syntax\n"
                    "  5:         else\n"
                    "            ^\n"
                    )
                f = open('result.output', 'w'); f.write(s); f.close()
                del s

    def after(self):
        os.chdir(self.CWD)

    def _test(self):
        result_files = glob('result*.output')
        for fname in result_files:
            sys.stdout.write(' %s' % fname)
            result = open(fname).read()
            command, expected = re.split(r'\n', result, 1)
            command = re.sub('^\$ ', '', command)
            if self.__name__ == 'logging':
                sin, sout, serr = _popen3(command)
                sin.close()
                actual = sout.read() + serr.read()
                sout.close()
                serr.close()
                if python3:
                    actual = actual.decode('utf-8')
                actual = re.sub(r'file=.*?/test_logging/', "file='/home/user/", actual)
            else:
                actual = os.popen(command).read()
                if self.__name__ == 'm17n':
                    expected = re.sub(r'timestamp: \d+(\.\d+)?', 'timestamp: 0.0', expected)
                    actual   = re.sub(r'timestamp: \d+(\.\d+)?', 'timestamp: 0.0', actual)
            if self._testMethodName == 'test_nested':
                expected = re.sub(r'[ \t]*\#.*', '', expected)
            ok (actual) == expected
        if not result_files:
            fname = glob('*main*.py')[0]
            command = sys.executable + " " + fname
            actual = os.popen(command).read()
            fname = glob('*.expected')[0]
            f = open(fname); expected = f.read(); f.close()
            ok (actual) == expected
        sys.stdout.write(' )')
""")
    for tname in testnames:
        if not tname.startswith('test_'):
            tname = 'test_' + tname
        buf.append(r"""
    def %s(self):
        self._test()
""" % tname)
    buf.append(r"""
if __name__ == '__main__':
    run()
""")
    return "".join(buf)


@recipe
@product(testdir+'/test_examples.py')
@ingreds('examples.txt')
def file_test_examples_py(c):
    testnames = [ os.path.basename(x) for x in glob('%s/data/examples/*' % testdir) ]
    s = _create_examples_test_py(testnames)
    open(c.product, 'w').write(s)

def _create_examples_test_py(testnames):
    buf = []
    buf.append(r"""
###
### auto generated by ../doc/Kookbook.py
###

import sys, os, re
from glob import glob
from oktest import ok, run

python3 = sys.version_info[0] == 3

try:    # Python 2.6 or later
    from subprocess import Popen, PIPE
    def _popen(command):
        sout = Popen(command, shell=True, stdout=PIPE).stdout
        return sout
except ImportError:
    def _popen(command):
        return os.popen(command)


class ExamplesTest(object):

    DIR = os.path.dirname(os.path.abspath(__file__)) + '/data/examples'
    CWD = os.getcwd()

    def before(self):
        #sys.stdout.write('\n** test_%s: (' % self.__name__)
        sys.stdout.write(' (')
        os.chdir(self.DIR + '/' + self.__name__)
        for x in glob('views/*.cache'):
            os.unlink(x)

    def after(self):
        os.chdir(self.CWD)

    def _test(self):
        for fname in glob('*.result'):
            sys.stdout.write(' %s' % fname)
            result = open(fname).read()
            command, expected = re.split(r'\n', result, 1)
            command = re.sub('^\$ ', '', command)
            actual = _popen(command).read()
            if python3:
                actual = actual.decode('utf-8')
            ok (actual) == expected
        sys.stdout.write(' )')
""")
    for tname in testnames:
        if not tname.startswith('test_'):
            tname = 'test_' + tname
        buf.append(r"""
    def %s(self):
        self._test()
""" % tname)
    buf.append(r"""
if __name__ == '__main__':
    run()
""")
    return "".join(buf)
