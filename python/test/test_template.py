###
### $Rev$
### $Release:$
### $Copyright$
###

import unittest
import sys, os, re

from testcase_helper import *
import tenjin
from tenjin.helpers import *


class TemplateTest(unittest.TestCase, TestCaseHelper):

    code = TestCaseHelper.generate_testcode(__file__)
    exec(code)


    def setUp(self):
        pass

    def tearDown(self):
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
                self.assertEqual(exception, ex.__class__)
                #self.assertTrue(isinstance(ex, exception))
                if errormsg:
                    ## SyntaxError has 'msg' attribute instead of 'message'. Why?
                    #self.assertEqual(errormsg, ex.message or ex.msg) # failed in python2.3
                    self.assertEqual(errormsg, ex.args[0])
                if filename:
                    self.assertEqual(filename, ex.filename)
        else:
            if templateclass:
                templateclass = eval(templateclass)
                template = templateclass(**options)
            else:
                template = tenjin.Template(**options)
            script = template.convert(input, filename)
            self.assertTextEqual(source, script, encoding=encoding)
            if expected:
                output = template.render(context)
                self.assertTextEqual(expected, output, encoding=encoding)



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
#        self.assertTextEqual(output1, output2)


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
            self.assertTextEqual(template1.script, template2.convert(input))
            self.assertTextEqual(template1.render(), template2.render())
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
            input = "#{base64.encodestring(b'tenjin')}"
        template = tenjin.Template()
        template.convert(input)
        def f1():
            template.render()
        self.assertRaises(NameError, f1)
        #tenjin.import_module('base64')
        globals()['base64'] = base64
        #self.assertNotRaise(f1)
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
        self.assertRaises(NameError, f1)
        if python2:
            #tenjin.import_module(rfc822)
            globals()['rfc822'] = rfc822
        elif python3:
            globals()['email'] = email
        #self.assertNotRaise(f1)
        f1()


    def test_invalid_template_args(self):
        def f():
            input = "<?py #@ARGS 1x ?>"
            template = tenjin.Template()
            template.convert(input)
        self.assertRaises(ValueError, f)


remove_unmatched_test_methods(TemplateTest)


if __name__ == '__main__':
    unittest.main()
