###
### $Release:$
### $Copyright$
###

from oktest import ok, not_ok, run
import sys, os, re

import tenjin
from tenjin.helpers import *


class SafeStrTest(object):

    def test___init__(self):
        if "arg is a string then keeps it to 'value' attr":
            s = '<foo>'
            ok (SafeStr(s).value).is_(s)
        if "arg is not a basestring then raises error":
            def f(): SafeStr(123)
            ok (f).raises(TypeError, "123 is not a string.")
            def f(): SafeStr(None)
            ok (f).raises(TypeError, "None is not a string.")

    def test___str__(self):
        if "called then returns itself":
            hs = SafeStr('foo')
            ok (hs.__str__()).is_(hs)
            ok (str(hs)).is_(hs)

    def test___unicode__(str):
        if "called then returns itself":
            hs = SafeStr('foo')
            ok (hs.__unicode__()).is_(hs)
            ok (unicode(hs)) == u'foo'


class SafeTemplateTest(object):

    input = ( "<?py for item in items: ?>\n"
              "<p>${item}</p>\n"
              "<?py #end ?>\n" )
    context = { 'items': [ '<>&"', SafeStr('<>&"') ] }
    expected = ( "<p>&lt;&gt;&amp;&quot;</p>\n"
                 "<p><>&\"</p>\n" )

    def test_get_expr_and_escapeflag(self):
        t = tenjin.SafeTemplate()
        if "matched expression is '${}' then returns expr string and True":
            m = t.expr_pattern().search("<p>${item}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('item', True)
        if "matched expression is '#{}' then raises error":
            m = t.expr_pattern().search("<p>#{item}</p>")
            def f(): t.get_expr_and_escapeflag(m)
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "'#{item}': '#{}' is not available in SafeTemplate.")

    def test_FUNCTEST_of_convert(self):
        if "input contains '#{}' then raises error":
            def f(): tenjin.SafeTemplate(input=self.input.replace('$', '#'))
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "'#{item}': '#{}' is not available in SafeTemplate.")
        if "converted then use 'safe_escape()' instead of 'escape()'":
            t = tenjin.SafeTemplate(input="<p>${item}</p>")
            ok (t.script) == "_buf.extend(('''<p>''', safe_escape(to_str(item)), '''</p>''', ));"

    def test_FUNCTEST_of_render(self):
        if "rendered then avoid escape of SafeStr object":
            t = tenjin.SafeTemplate(input=self.input)
            context = self.context.copy()
            ok (t.render(context)) == self.expected

    def test_FUNCTEST_with_engine(self):
        fname = 'test_safe_template.pyhtml'
        try:
            _tclass = tenjin.Engine.templateclass
            tenjin.Engine.templateclass = tenjin.SafeTemplate
            open(fname, 'w').write(self.input)
            engine = tenjin.Engine()
            output = engine.render(fname, self.context.copy())
            ok (output) == self.expected
        finally:
            tenjin.Engine.templateclass = _tclass
            for x in [fname, fname+'.cache']:
                os.path.isfile(x) and os.unlink(x)


class SafePreprocessorTest(object):

    input = ( "<?PY for i in range(2): ?>\n"
              "<h1>${{i}}</h1>\n"
              "<?py for item in items: ?>\n"
              "<p>${item}</p>\n"
              "<?py #end ?>\n"
              "<?PY #end ?>\n" )
    context = { 'items': [ '<>&"', SafeStr('<>&"') ] }
    expected = ( "<h1>1</h1>\n"
                 "<?py for item in items: ?>\n"
                 "<p>${item}</p>\n"
                 "<?py #end ?>\n"
                 "<h1>2</h1>\n"
                 "<?py for item in items: ?>\n"
                 "<p>${item}</p>\n"
                 "<?py #end ?>\n" )
    expected_script = r"""
_buf.extend(('''<h1>0</h1>\n''', ));
for item in items:
    _buf.extend(('''<p>''', safe_escape(to_str(item)), '''</p>\n''', ));
#end
_buf.extend(('''<h1>1</h1>\n''', ));
for item in items:
    _buf.extend(('''<p>''', safe_escape(to_str(item)), '''</p>\n''', ));
#end
"""[1:]

    def test_get_expr_and_escapeflag(self):
        t = tenjin.SafePreprocessor()
        if "matched expression is '${{}}' then returns expr string and True":
            m = t.expr_pattern().search("<p>${{item}}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('item', True)
        if "matched expression is '#{{}}' then raises error":
            m = t.expr_pattern().search("<p>#{{item}}</p>")
            def f(): t.get_expr_and_escapeflag(m)
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "'#{item}': '#{{}}' is not available in SafePreprocessor.")

    def test_FUNCTEST_with_engine(self):
        fname = 'test_safe_preprocessor.pyhtml'
        self._unlink = [fname, fname + '.cache']
        try:
            _backup = tenjin.Engine.templateclass
            tenjin.Engine.templateclass = tenjin.SafeTemplate
            open(fname, 'w').write(self.input)
            engine = tenjin.Engine(preprocess=tenjin.SafePreprocessor)
            t = engine.get_template(fname)
            ok (t.script) == self.expected_script
        finally:
            tenjin.Engine.templateclass = _backup
            for x in [fname, fname+'.cache']:
                os.path.isfile(x) and os.unlink(x)


if __name__ == '__main__':
    run()
