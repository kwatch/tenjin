###
### $Release:$
### $Copyright$
###

from oktest import ok, not_ok, run
import sys, os, re

from testcase_helper import *
import tenjin
from tenjin.helpers import *


class TemplateTest(object):

    code = TestCaseHelper.generate_testcode(__file__)
    exec(code)


    def before(self):
        pass

    def after(self):
        pass

    def _test(self):
        input     = getattr(self, 'input', None)
        source    = getattr(self, 'source', None)
        expected  = getattr(self, 'expected', None)
        exception = getattr(self, 'exception', None)
        errormsg  = getattr(self, 'errormsg', None)
        options   = getattr(self, 'options', {})
        filename  = getattr(self, 'filename', None)
        context   = getattr(self, 'context', {})
        testopts  = getattr(self, 'testopts', None)
        disabled  = getattr(self, 'disabled', None)
        templateclass = getattr(self, 'templateclass', None)
        encoding  = None
        #
        if disabled:
            return
        #
        if testopts:
            if 'crchar' in testopts:
                ch = testopts['crchar']
                if input:     input    = input.replace(ch, "\r")
                if source:    source   = source.replace(ch, "\r")
                if expected:  expected = expected.replace(ch, "\r")
            if testopts.get('escapefunc') == 'cgi.escape':
                import cgi
                context['escape'] = cgi.escape
            if testopts.get('tostrfunc') == 'str':
                context['to_str'] = str
            if 'encoding' in testopts:
                encoding = testopts.get('encoding')
            if 'templateclass' in testopts:
                templateclass = testopts.get('templateclass')
        #
        if python3:
            input  = input.replace('urllib.quote', 'urllib.parse.quote')
            source = source.replace('urllib.quote', 'urllib.parse.quote')
            if encoding:
                if source:
                    source = source.replace("u'''", "'''").replace("u'", "'")
                    input  = input.replace("u'", "'")
        #
        if exception:
            try:
                template = tenjin.Template(**options)
                template.convert(input, filename)
                template.render(context)
                self.fail('%s is expected but not raised.' % exception)
            except Exception:
                ex = sys.exc_info()[1]
                ok (ex.__class__) == exception
                #ok (ex).is_a(exception)
                if errormsg:
                    ## SyntaxError has 'msg' attribute instead of 'message'. Why?
                    #ok (ex.message or ex.msg) == errormsg # failed in python2.3
                    ok (ex.args[0]) == errormsg
                if filename:
                    ok (ex.filename) == filename
        else:
            if templateclass:
                templateclass = eval(templateclass)
                template = templateclass(**options)
            else:
                template = tenjin.Template(**options)
            script = template.convert(input, filename)
            ok (script) == source         # encoding=encoding
            if expected:
                output = template.render(context)
                ok (output) == expected   # encoding=encoding



#    def test_render1(self):   # Tenjin#render(context) == Tenjin#render(**context)
#        input = """<ul>
#<?py for item in items: ?>
#<li>#{item}</li>
#<?py #endfor ?>
#</ul>
#"""
#        template = tenjin.Template()
#        template.convert(input)
#        items = ['foo', 'bar', 'baz']
#        context = {'items': items}
#        output1 = template.render(context)
#        output2 = template.render(items=items)
#        ok (output2) == output1


    def test_filename1(self):
        input = """<ul>
<?py for i in range(0,3): ?>
<li>#{i}</li>
<?py #endfor ?>
</ul>
"""
        filename = 'test_filename1.tenjin'
        try:
            write_file(filename, input)
            template1 = tenjin.Template(filename)
            template2 = tenjin.Template()
            ok (template2.convert(input)) == template1.script
            ok (template2.render()) == template1.render()
        finally:
            try:
                os.remove(filename)
            except:
                pass


    def test_import_module1(self):
        import base64
        if python2:
            input = "#{base64.encodestring('tenjin')}"
        elif python3:
            if hasattr(base64, 'encodebytes'):             # python 3.1 or later
                input = "#{base64.encodebytes(b'tenjin')}"
            else:                                          # python 3.0
                input = "#{base64.encodestring(b'tenjin')}"
        template = tenjin.Template()
        template.convert(input)
        def f1():
            template.render()
        ok (f1).raises(NameError)
        #tenjin.import_module('base64')
        globals()['base64'] = base64
        #ok (f1).not_raise()
        f1()


    def test_import_module2(self):
        if python2:
            import rfc822
            input = "#{rfc822.formatdate()}"
        elif python3:
            import email.utils
            input = "#{email.utils.formatdate()}"
        template = tenjin.Template()
        template.convert(input)
        def f1():
            template.render()
        ok (f1).raises(NameError)
        if python2:
            #tenjin.import_module(rfc822)
            globals()['rfc822'] = rfc822
        elif python3:
            globals()['email'] = email
        #ok (f1).not_raise()
        f1()


    def test_invalid_template_args(self):
        def f():
            input = "<?py #@ARGS 1x ?>"
            template = tenjin.Template()
            template.convert(input)
        ok (f).raises(ValueError)

#    def test_dummy_if_stmt(self):     ## NEVER!
#        input = r"""
#<html>
#  <body>
#    <ul>
#      <?py if items: ?>
#      <?py   for item in items: ?>
#      <li>#{item}</li>
#      <?py   #endfor ?>
#      <?py #endif ?>
#    </ul>
#  </body>
#</html>
#"""[1:]
#        expected = r"""
#_buf.extend(('''<html>
#  <body>
#    <ul>\n''', ));
#if True: ## dummy
#      if items:
#        for item in items:
#            _buf.extend(('''      <li>''', to_str(item), '''</li>\n''', ));
#        #endfor
#      #endif
#      _buf.extend(('''    </ul>
#  </body>
#</html>\n''', ));
#"""[1:]
#        t = tenjin.Template()
#        actual = t.convert(input)
#        ok (actual) == expected


    def test_input(self):
        input = r"""<!DOCTYPE>
<ul>
<?py for item in items: ?>
  <li>#{item}</li>
<?py #endfor ?>
</ul>
"""
        script = r"""_buf.extend(('''<!DOCTYPE>
<ul>\n''', ));
for item in items:
    _buf.extend(('''  <li>''', to_str(item), '''</li>\n''', ));
#endfor
_buf.extend(('''</ul>\n''', ));
"""
        t = tenjin.Template("test.foobar.pyhtml", input=input)
        if "input argument is specified then regard it as template content":
            ok (t.script) == script
        if "input argument is specified then timestamp is set to False":
            ok (t.timestamp) == False


    def test_trace(self):
        if "trace is on then prints template filename as HTML comments":
            filename = "test.trace.pyhtml"
            input = "<p>hello #{name}!</p>\n"
            expected = ( "<!-- ***** begin: %s ***** -->\n"
                         "<p>hello world!</p>\n"
                         "<!-- ***** end: %s ***** -->\n" ) % (filename, filename)
            t = tenjin.Template(filename, input=input, trace=True)
            output = t.render({'name':'world'})
            ok (output) == expected


if __name__ == '__main__':
    run()
