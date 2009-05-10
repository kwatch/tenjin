# -*- coding: utf-8 -*-
###
### $Rev$
### $Release:$
### $Copyright$
###

import unittest
import os, traceback

from testcase_helper import *
import tenjin
from tenjin.helpers import escape, to_str

filename = None
for filename in ['../bin/pytenjin', 'bin/pytenjin']:
    if os.path.exists(filename):
        break

_name_orig = __name__
__name__ = 'dummy'
execfile(filename)
__name__ = _name_orig


def to_list(value):
    if isinstance(value, list):
        return value
    return [value]


import sys
python_version = sys.version.split(' ')[0]


INPUT = r"""<ul>
<?py for item in ['<a&b>', '["c",'+"'d']"]: ?>
  <li>#{item}
      ${item}</li>
<?py #end ?>
</ul>
"""
INPUT2 = """<ul>\r\n\
<?py for item in ['<a&b>', '["c",'+"'d']"]: ?>\r\n\
  <li>#{item}\r\n\
      ${item}</li>\r\n\
<?py #end ?>\r\n\
</ul>\r\n\
"""
INPUT3 = r"""<?py
#title = _context['title']
#items = _context.items
?>
<h1>#{title}</h1>
<ul>
<?py for item in items: ?>
  <li>#{item}</li>
<?py #endfor ?>
</ul>
"""

SOURCE = r"""_buf = []; _buf.extend(('''<ul>\n''', ));
for item in ['<a&b>', '["c",'+"'d']"]:
    _buf.extend(('''  <li>''', to_str(item), '''
      ''', escape(to_str(item)), '''</li>\n''', ));
#end
_buf.extend(('''</ul>\n''', ));
print ''.join(_buf)
"""
SOURCE2 = """_buf = []; _buf.extend(('''<ul>\\r\\n''', ));\n\
for item in ['<a&b>', '["c",'+"'d']"]:\n\
    _buf.extend(('''  <li>''', to_str(item), '''\r\n\
      ''', escape(to_str(item)), '''</li>\\r\\n''', ));\n\
#end\n\
_buf.extend(('''</ul>\\r\\n''', ));\n\
print ''.join(_buf)
"""

EXECUTED = r"""<ul>
  <li><a&b>
      &lt;a&amp;b&gt;</li>
  <li>["c",'d']
      [&quot;c&quot;,'d']</li>
</ul>
"""
EXECUTED2 = """<ul>\r\n\
  <li><a&b>\r\n\
      &lt;a&amp;b&gt;</li>\r\n\
  <li>["c",'d']\r\n\
      [&quot;c&quot;,'d']</li>\r\n\
</ul>\r\n\
"""
EXECUTED3 = r"""<h1>tenjin example</h1>
<ul>
  <li>aaa</li>
  <li>bbb</li>
  <li>ccc</li>
</ul>
"""

CONTEXT1 = r"""
title: tenjin example
items:
	- aaa
	- bbb
	- ccc
"""
CONTEXT2 = r"""
title = 'tenjin example'
items = ['aaa', 'bbb', 'ccc']
"""


class MainTest(unittest.TestCase, TestCaseHelper):

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def _test(self):
        if not self.is_target(depth=3): return
        #
        input     = getattr(self, 'input', '')
        source    = getattr(self, 'source', None)
        expected  = getattr(self, 'expected', None)
        exception = getattr(self, 'exception', None)
        errormsg  = getattr(self, 'errormsg', None)
        options   = getattr(self, 'options', '')
        filename  = getattr(self, 'filename', None)
        context_file = getattr(self, 'context_file', None)
        context_data = getattr(self, 'context_data', None)
        encoding  = getattr(self, 'encoding', None)
        #
        if python_version < '2.5':
            if expected:
                expected = expected.replace(': unexpected indent', ': invalid syntax')
        #
        if filename is not False:
            if filename is None:
                filename = '.test.pyhtml'
            #open(filename, 'w').write(input)
            for fname, s in zip(to_list(filename), to_list(input)):
                if encoding and isinstance(s, unicode):
                    s = s.encode(encoding)
                open(fname, 'w').write(s)
        #
        if isinstance(options, list):
            argv = options
        elif isinstance(options, str):
            argv = [item for item in options.split(' ') if item]
        argv.insert(0, 'tenjin')
        if filename:
            #argv.append(filename)
            argv.extend(to_list(filename))
        #print "*** debug: argv=%s" % repr(argv)
        #
        if context_file:
            s = context_data
            if encoding and instance(s, unicode):
                s = s.encode(encoding)
            open(context_file, 'w').write(s)
        #
        try:
            app = Main(argv)
            if exception:
                lst = [None]
                def f1():
                    try:
                        output = app.execute()
                    except Exception, err:
                        lst[0] = err
                        raise err
                self.assertRaises(exception, f1)
                if errormsg:
                    ex = lst[0]
                    self.assertTextEqual(errormsg, str(ex))
            else:
                output = app.execute()
                #print "*** expected=%s" % repr(expected)
                #print "*** output=%s" % repr(output)
                if encoding and isinstance(output, unicode):
                    output = output.encode(encoding)
                self.assertTextEqual(expected, output)
        finally:
            try:
                if filename:
                    #os.remove(filename)
                    for fname in to_list(filename):
                        os.unlink(fname)
                if context_file:
                    os.remove(context_file)
            except:
                pass

    code = TestCaseHelper.generate_testcode(__file__)
    exec code



    def test_help(self):  # -h, --help
        if not self.is_target(): return
        self.options  = "-h"
        self.input    = ""
        self.expected = Main(['tenjin']).usage('tenjin')
        self._test()
        #
        self.options  = "--help"
        self._test()

    def test_version(self):  # -v, --version
        if not self.is_target(): return
        self.options  = "-v"
        self.input    = ""
        self.expected = Main(['tenjin']).version() + "\n"
        self._test()
        self.options = '--version'
        self._test()

#    def test_help_and_version(self):  # -hVz
#        if not self.is_target(): return
#        self.options  = "-hVc"
#        self.input    = "<?py foo() ?>"
#        app = Main(['tenjin'])
#        self.expected = app.version() + "\n" + app.usage('tenjin')
#        self._test()

    def test_render(self):  # (nothing), -a render
        if not self.is_target(): return
        self.options  = ""
        self.input    = INPUT
        self.expected = EXECUTED
        self._test()
        self.options  = "-a render"
        self._test()

    def test_source(self):  # -s, -a convert
        if not self.is_target(): return
        self.options  = "-s"
        self.input    = INPUT
        self.expected = SOURCE
        self._test()
        self.options = "-a convert"
        self._test()

    def test_source2(self):  # -s, -aconvert
        if not self.is_target(): return
        self.options  = "-s"
        n1 = len("<ul>\n")
        n2 = len("</ul>\n")
        self.input    = INPUT[n1:-n2]
        buf = SOURCE.splitlines(True)[1:-2]
        buf.insert(0, "_buf = []\n")
        buf.append("print ''.join(_buf)\n")
        self.expected = ''.join(buf)
        self._test()
        self.options = "-aconvert"
        self._test()

    def test_source3(self):  # -sb, -baconvert
        if not self.is_target(): return
        self.options  = "-sb"
        self.input    = INPUT
        n1 = len("_buf = []; ")
        n2 = len("print ''.join(_buf)\n")
        self.expected = SOURCE[n1:-n2]
        self._test()
        self.options = "-baconvert"
        self._test()

    def test_cache1(self):   # -a cache
        if not self.is_target(): return
        self.options  = "-a cache"
        self.input    = (
            '<?py #@ARGS title, items ?>\n'
            '<h1>${title}</h1>\n'
            '<ul>\n'
            '<?py for item in items: ?>\n'
            '  <li>${item}</li>\n'
            '<?py #endfor ?>\n'
            '</ul>\n'
            )
        self.expected = ''
        script = (
            "title = _context.get('title'); items = _context.get('items'); \n"
            "_buf.extend(('''<h1>''', escape(to_str(title)), '''</h1>\n"
            "<ul>\\n''', ));\n"
            "for item in items:\n"
            "    _buf.extend(('''  <li>''', escape(to_str(item)), '''</li>\\n''', ));\n"
            "#endfor\n"
            "_buf.extend(('''</ul>\\n''', ));\n"
            )
        self.filename = 'test_cache1.pyhtml'
        cachename = self.filename + '.cache'
        try:
            self._test()
            self.assertTrue(os.path.exists(cachename))
            import marshal
            dct = marshal.load(open(cachename, 'rb'))
            self.assertTextEqual(['title', 'items'], dct.get('args'))
            self.assertEquals("<type 'code'>", str(type(dct.get('bytecode'))))
            self.assertTextEqual(script, dct.get('script'))
        finally:
            if os.path.exists(cachename):
                os.unlink(cachename)

    input_for_retrieve = (
        '<div>\n'
        '<?py if list: ?>\n'
        '  <table>\n'
        '    <thead>\n'
        '      <tr>\n'
        '        <th>#</th><th>item</th>\n'
        '      </tr>\n'
        '    </thead>\n'
        '    </tbody>\n'
        '    <?py i = 0 ?>\n'
        '    <?py for item in list: ?>\n'
        '\t<?py i += 1 ?>\n'
        '      <tr bgcolor="#{i % 2 and "#FFCCCC" or "#CCCCFF"}">\n'
        '\t<td>${i}</td>\n'
        '        <td>${item}</td>\n'
        '      </tr>\n'
        '    <?py #end ?>\n'
        '    </tbody>\n'
        '  </table>\n'
        '<?py #end ?>'
        '</div>\n'
        )
    expected_for_retrieve = '\n'.join((
        '_buf = []; ',
        'if list:',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '    i = 0',
        '    for item in list:',
        '\ti += 1',
        '                   to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
        '\t    escape(to_str(i)); ',
        '            escape(to_str(item)); ',
        '',
        '    #end',
        '',
        '',
        '#end',
        'print \'\'.join(_buf)',
        ''))

    def test_retrieve(self):  # -S, -a retrieve
        if not self.is_target(): return
        self.input    = self.input_for_retrieve
        self.expected = self.expected_for_retrieve
        self.options = '-S'
        self._test()
        self.options = '-a retrieve'
        self._test()

    def test_retrieve2(self):  # -SU, -SNU
        if not self.is_target(): return
        expected = '\n'.join((
            '_buf = []; ',
            'if list:',
            '',
            '    i = 0',
            '    for item in list:',
            '\ti += 1',
            '                   to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
            '\t    escape(to_str(i)); ',
            '            escape(to_str(item)); ',
            '',
            '    #end',
            '',
            '#end',
            'print \'\'.join(_buf)',
            ''))
        self.input = self.input_for_retrieve
        self.expected = expected
        self.options = '-SU'
        self._test()
        #
        expected = '\n'.join((
            '    1:  _buf = []; ',
            '    2:  if list:',
            '',
            '   10:      i = 0',
            '   11:      for item in list:',
            '   12:  \ti += 1',
            '   13:                     to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
            '   14:  \t    escape(to_str(i)); ',
            '   15:              escape(to_str(item)); ',
            '',
            '   17:      #end',
            '',
            '   20:  #end',
            '   21:  print \'\'.join(_buf)',
            ''))
        self.expected = expected
        self.options = '-SNU'
        self._test()

    def test_retrieve3(self):  # -SC, -SNC
        if not self.is_target(): return
        expected = '\n'.join((
            '_buf = []; ',
            'if list:',
            '    i = 0',
            '    for item in list:',
            '\ti += 1',
            '                   to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
            '\t    escape(to_str(i)); ',
            '            escape(to_str(item)); ',
            '    #end',
            '#end',
            'print \'\'.join(_buf)',
            ''))
        self.input = self.input_for_retrieve
        self.expected = expected
        self.options = '-SC'
        self._test()
        #
        expected = '\n'.join((
            '    1:  _buf = []; ',
            '    2:  if list:',
            '   10:      i = 0',
            '   11:      for item in list:',
            '   12:  \ti += 1',
            '   13:                     to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
            '   14:  \t    escape(to_str(i)); ',
            '   15:              escape(to_str(item)); ',
            '   17:      #end',
            '   20:  #end',
            '   21:  print \'\'.join(_buf)',
            ''))
        self.expected = expected
        self.options = '-SNC'
        self._test()

    def test_statements(self):  # -X, -a statements
        if not self.is_target(): return
        expected = '\n'.join((
            '_buf = []; ',
            'if list:',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '    i = 0',
            '    for item in list:',
            '\ti += 1',
            '',
            '',
            '',
            '',
            '    #end',
            '',
            '',
            '#end',
            'print \'\'.join(_buf)',
            ''))
        self.input = self.input_for_retrieve
        self.expected = expected
        self.options = '-X'
        self._test()
        self.options = '-a statements'
        self._test()

    def test_dump(self):  # -d, -a dump
        if not self.is_target(): return
        # create cache file
        filename = '_test_dump.pyhtml'
        cachename = filename + '.cache'
        self.filename = filename
        self.input = INPUT
        self.expected = EXECUTED
        self.options = '-a render --cache=true'
        self._test()
        self.assertTrue(os.path.exists(cachename))
        # dump test
        try:
            self.filename = False
            self.input    = False
            self.expected = SOURCE[len('_buf = []; '):-len("print ''.join(_buf)\n")]
            #self.options = '-d %s' % cachename
            #self._test()
            self.options = '-a dump %s' % cachename
            self._test()
        finally:
            os.unlink(cachename)

    def test_indent(self):  # -i2
        if not self.is_target(): return
        self.options  = "-si2"
        self.input    = INPUT
        self.expected = SOURCE.replace('    _buf', '  _buf')
        self._test()

    def test_quiet(self):  # -q, -qasyntax
        if not self.is_target(): return
        self.options  = "-z"
        input = INPUT
        self.input    = [input, input, input]
        basename = ".test_quiet%d.pyhtml"
        self.filename = [basename % i for i in range(0,3)]
        self.expected = ''.join([(basename+" - ok.\n") % i for i in range(0,3)])
        self._test()
        #
        self.options  = "-zq"
        self.expected = ""
        self._test()
        self.options = "-qasyntax"
        self._test()

    def test_invalid_options(self):  # -Y, -i, -f, -c, -i foo
        if not self.is_target(): return
        self.input    = INPUT
        self.expected = ""
        self.exception = CommandOptionError
        #
        self.options  = "-hY"
        self.errormsg = "-Y: unknown option."
        self._test()
        #
        self.options  = "-i"
        self.filename = False
        #self.errormsg = "-i: indent width required."
        self.errormsg = "-i: argument required."
        self._test()
        #
        self.options  = "-f"
        self.filename = False
        #self.errormsg = "-f: context data filename required."
        self.errormsg = "-f: argument required."
        self._test()
        #
        self.options  = "-c"
        self.filename = False
        #self.errormsg = "-c: context data string required."
        self.errormsg = "-c: argument required."
        self._test()
        #
        self.options  = "-i foo"
        self.errormsg = "-i: integer value required."
        self._test()
        #

    def test_newline(self):
        if not self.is_target(): return
        self.options  = "-s"
        self.input    = INPUT2
        self.expected = SOURCE2
        self._test()
        self.options  = ""
        self.expected = EXECUTED2
        self._test()

    def test_datafile_yaml(self): # -f datafile.yaml
        if not self.is_target(): return
        context_filename = 'test.datafile.yaml'
        self.options  = "-f " + context_filename
        self.input    = INPUT3
        self.expected = EXECUTED3
        self.context_file = context_filename
        self.context_data = CONTEXT1
        self._test()

    def test_datafile_py(self): # -f datafile.py
        if not self.is_target(): return
        context_filename = 'test.datafile.py'
        self.options  = "-f " + context_filename
        self.input    = INPUT3
        self.expected = EXECUTED3
        self.context_file = context_filename
        self.context_data = CONTEXT2
        self._test()

    def test_datafile_error(self):  # -f file.txt, not-a-mapping context data
        if not self.is_target(): return
        context_filename = 'test.datafile.txt'
        self.options = "-f " + context_filename
        self.exception = CommandOptionError
        self.errormsg = "-f %s: file not found." % context_filename
        self._test()
        #
        self.context_file = context_filename
        self.context_data = "- foo\n- bar\n -baz"
        self.errormsg = "-f %s: unknown file type ('*.yaml' or '*.py' expected)." % context_filename
        self._test()
        #
        context_filename = 'test.datafile.yaml'
        self.options = "-f " + context_filename
        self.errormsg = "%s: not a mapping (dictionary)." % context_filename
        self.context_file = context_filename
        self._test()

    def test_context_yaml(self):  # -c yamlstr
        if not self.is_target(): return
        self.options = ['-c', '{title: tenjin example, items: [aaa, bbb, ccc]}']
        self.input    = INPUT3
        self.expected = EXECUTED3
        self._test()

    def test_context_py(self):  # -c python-code
        if not self.is_target(): return
        self.options = ['-c', 'title="tenjin example";  items=["aaa", "bbb", "ccc"]']
        self.input    = INPUT3
        self.expected = EXECUTED3
        self._test()

    def test_untabify(self):  # -T
        if not self.is_target(): return
        context_filename = 'test.datafile.yaml'
        self.options  = "-Tf " + context_filename
        self.input    = INPUT3
        self.expected = EXECUTED3
        self.context_file = context_filename
        self.context_data = CONTEXT1
        self.exception = yaml.parser.ScannerError
        self._test()

    def test_modules(self):  # -r modules
        if not self.is_target(): return
        self.options  = "--escapefunc=cgi.escape"
        self.input    = INPUT
        self.expected = EXECUTED.replace('&quot;', '"')
        self.exception = NameError
        self.errormsg = "name 'cgi' is not defined"
        self._test()
        #
        self.options  = "-r cgi,os,sys --escapefunc=cgi.escape"
        self.input    = INPUT
        self.expected = EXECUTED.replace('&quot;', '"')
        self.exception = None
        self.errormsg = None
        self._test()

    def test_modules_err(self):  # -r hogeratta
        if not self.is_target(): return
        self.options = '-r hogeratta'
        self.exception = CommandOptionError
        self.errormsg = '-r hogeratta: module not found.'
        self._test()

    def test_escapefunc(self):  # --escapefunc=cgi.escape
        if not self.is_target(): return
        self.options  = "-s --escapefunc=cgi.escape"
        self.input    = INPUT
        self.expected = SOURCE.replace('escape', 'cgi.escape')
        self._test()

    def test_tostrfunc(self):  # --tostrfunc=str
        if not self.is_target(): return
        self.options  = "-s --tostrfunc=str"
        self.input    = INPUT
        self.expected = SOURCE.replace('to_str', 'str')
        self._test()

    def test_preamble(self):  # --preamble --postamble
        if not self.is_target(): return
        self.options  = ["-s", "--preamble=_buf=list()", "--postamble=return ''.join(_buf)"]
        self.input    = INPUT
        self.expected = SOURCE.replace("_buf = []", "_buf=list()").replace("print ", "return ")
        self._test()

    def test_xencoding1(self):  # --encoding=encoding
        if not self.is_target(): return
        self.input = """\
<?py items=['foo',u'bar',u'日本語'] ?>
ようこそ
<?py for item in items: ?>
* 「${item}」
<?py #end ?>
"""
        self.expected = """\
ようこそ
* 「foo」
* 「bar」
* 「日本語」
"""
        #
        self.encoding = 'utf-8'
        self.options  = "--encoding=%s" % self.encoding
        self._test()

    def test_xencoding2(self):  # -k encoding
        if not self.is_target(): return
        self.input = """\
<?py items=['foo',u'bar','日本語'] ?>
ようこそ
<?py for item in items: ?>
* 「${item}」
<?py #end ?>
"""
        self.expected = """\
ようこそ
* 「foo」
* 「bar」
* 「日本語」
"""
        #
        self.encoding = 'utf-8'
        self.options  = "-k utf-8"
        tostr_func = to_str
        try:
            self._test()
        finally:
            globals()['tostr'] = tostr_func

    def test_template_path(self):  # --path
        if not self.is_target(): return
        layout = r'''<html>
  <body>
#{_content}
<?py include(':footer') ?>
  </body>
</html>
'''
        body = r'''<ul>
<?py for item in 'ABC': ?>
  <li>${item}</li>
<?py #endfor ?>
</ul>
'''
        footer = r'''<hr />
<a href="mailto:webmaster@localhost">webmaser</a>
'''
        expected = r'''<html>
  <body>
<ul>
  <li>A</li>
  <li>B</li>
  <li>C</li>
</ul>

<hr />
<a href="mailto:webmaster@localhost">webmaser</a>
  </body>
</html>
'''
        try:
            os.mkdir("tmpl9")
            os.mkdir("tmpl9/user")
            open("tmpl9/layout.pyhtml", 'w').write(layout)
            open("tmpl9/body.pyhtml", 'w').write('')
            open("tmpl9/footer.pyhtml", 'w').write('')
            open("tmpl9/user/body.pyhtml", 'w').write(body)
            open("tmpl9/user/footer.pyhtml", 'w').write(footer)
            self.options  = "--path=.,tmpl9/user,tmpl9 --postfix=.pyhtml --layout=:layout"
            self.input = "<?py include(':body') ?>"
            self.expected = expected
            self._test()
        finally:
            from glob import glob
            for f in glob('tmpl9/user/*.pyhtml'): os.unlink(f)
            for f in glob('tmpl9/*.pyhtml'): os.unlink(f)
            for d in ['tmpl9/user', 'tmpl9']: os.rmdir(d)

    def test_preprocess1(self):  # -P, -a preprocess, --preprocess
        if not self.is_target(): return
        input = '''\
<?PY states = { "CA": "California", ?>
<?PY            "NY": "New York", ?>
<?PY            "FL": "Florida", } ?>
<?PY # ?>
<?py chk = { params['state']: ' checked="checked"' } ?>
<?PY codes = states.keys() ?>
<?PY codes.sort() ?>
<select name="state">
  <option value="">-</option>
<?PY for code in codes: ?>
  <option value="#{{code}}"#{chk.get(#{{repr(code)}}, '')}>${{states[code]}}</option>
<?PY #endfor ?>
</select>
'''
        script = '''\
<?py chk = { params['state']: ' checked="checked"' } ?>
<select name="state">
  <option value="">-</option>
  <option value="CA"#{chk.get('CA', '')}>California</option>
  <option value="FL"#{chk.get('FL', '')}>Florida</option>
  <option value="NY"#{chk.get('NY', '')}>New York</option>
</select>
'''
        expected = '''\
<select name="state">
  <option value="">-</option>
  <option value="CA" checked="checked">California</option>
  <option value="FL">Florida</option>
  <option value="NY">New York</option>
</select>
'''
        try:
            self.options  = "-P" # "-P --prefix=prep_ --postfix=.pyhtml"
            self.input = input
            self.expected = script
            self._test()
            self.options = "-a preprocess"
            self._test()
            #
            self.options  = ["--preprocess=true", "-c", "{params: {state: CA}}"]
            self.input = input
            self.expected = expected
            self._test()
        finally:
            pass


name = os.environ.get('TEST')
if name:
    for m in dir(MainTest):
        if m.startswith('test_') and m != 'test_'+name:
            delattr(MainTest, m)


if __name__ == '__main__':
    unittest.main()
