# -*- coding: utf-8 -*-

###
### $Release:$
### $Copyright$
###

from oktest import ok, not_ok, run
import sys, os, re

from testcase_helper import *
import tenjin
from tenjin.helpers import *


class EncodingTest(object):


    def _test_render(self, template=None, to_str=None,
                     expected_buf=None, expected_output=None,
                     expected_errcls=None, expected_errmsg=None):
        buf = []
        context = {'to_str': to_str}
        template.render(context, _buf=buf)
        ok (buf) == expected_buf
        if expected_errcls:
            def f():
                template.render(context)
            ok (f).raises(expected_errcls)
            ex = f.exception
            if expected_errmsg:
                ok (str(ex)) == expected_errmsg
        elif expected_output:
            def f():
                lambda: template.render(context)
            ok (f).not_raise()
            output = template.render(context)
            ok (output) == expected_output
            ok (output).is_a(type(output))
        else:
            raise "*** internal error"

    def test_with_binary_template_and_binary_data(self):
        t = tenjin.Template()
        input = "**あ**\n#{'あ'}\n"
        script = "_buf.extend(('''**\xe3\x81\x82**\n''', to_str('\xe3\x81\x82'), '''\\n''', ));\n"
        ok (t.convert(input)) == script
        ## do nothing in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode=None),
            expected_buf    = ['**\xe3\x81\x82**\n', '\xe3\x81\x82', '\n'],
            expected_output = "**あ**\nあ\n"
        )
        ## encode unicode into binary in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode='utf-8', decode=None),
            expected_buf    = ['**\xe3\x81\x82**\n', '\xe3\x81\x82', '\n'],
            expected_output = "**あ**\nあ\n"
        )
        ## decode binary into unicode in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode='utf-8'),
            expected_buf    = ['**\xe3\x81\x82**\n', u'\u3042', '\n'],
            expected_errcls = UnicodeDecodeError,
            expected_errmsg = "'ascii' codec can't decode byte 0xe3 in position 2: ordinal not in range(128)"
        )

    def test_with_unicode_template_and_binary_data(self):
        t = tenjin.Template(encoding='utf-8')
        input = "**あ**\n#{'あ'}\n"
        script = u"_buf.extend((u'''**\u3042**\n''', to_str('\u3042'), u'''\\n''', ));\n"
        ok (t.convert(input)) == script
        ## do nothing in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode=None),
            expected_buf    = [u'**\u3042**\n', '\xe3\x81\x82', u'\n'],
            expected_errcls = UnicodeDecodeError,
            expected_errmsg = "'ascii' codec can't decode byte 0xe3 in position 0: ordinal not in range(128)"
         )
        ## encode unicode in binary in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode='utf-8', decode=None),
            expected_buf    = [u'**\u3042**\n', '\xe3\x81\x82', u'\n'],
            expected_errcls = UnicodeDecodeError,
            expected_errmsg = "'ascii' codec can't decode byte 0xe3 in position 0: ordinal not in range(128)"
         )
        ## decode binary into unicode in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode='utf-8'),
            expected_buf    = [u'**\u3042**\n', u'\u3042', u'\n'],
            expected_output = u"**あ**\nあ\n"
        )

    def test_binary_template_with_unicode_data(self):
        t = tenjin.Template()
        input = "**あ**\n#{u'あ'}\n"
        script = "_buf.extend(('''**\xe3\x81\x82**\n''', to_str(u'\xe3\x81\x82'), '''\\n''', ));\n"
        ok (t.convert(input)) == script
        ## do nothing in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode=None),
            #expected_buf    = ['**\xe3\x81\x82**\n', u'\u3042', '\n'],
            expected_buf    = ['**\xe3\x81\x82**\n', u'\xe3\x81\x82', '\n'],
            expected_errcls = UnicodeDecodeError,
            expected_errmsg = "'ascii' codec can't decode byte 0xe3 in position 2: ordinal not in range(128)"
         )
        ## encode unicode in binary in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode='utf-8', decode=None),
            expected_buf    = ['**\xe3\x81\x82**\n', '\xc3\xa3\xc2\x81\xc2\x82', '\n'],
            expected_output = "**あ**\n\xc3\xa3\xc2\x81\xc2\x82\n"    ## GARGLED!!
         )
        ## decode binary into unicode in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode='utf-8'),
            expected_buf    = ['**\xe3\x81\x82**\n', u'\xe3\x81\x82', '\n'],
            expected_errcls = UnicodeDecodeError,
            expected_errmsg = "'ascii' codec can't decode byte 0xe3 in position 2: ordinal not in range(128)"
        )

    def test_unicode_template_with_unicode_data(self):
        t = tenjin.Template(encoding='utf-8')
        input = "**あ**\n#{u'あ'}\n"
        script = u"_buf.extend((u'''**\u3042**\n''', to_str(u'\u3042'), u'''\\n''', ));\n"
        ok (t.convert(input)) == script
        ## do nothing in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode=None),
            expected_buf    = [u'**\u3042**\n', u'\u3042', u'\n'],
            expected_output = u"**あ**\nあ\n"
         )
        ## encode unicode in binary in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode='utf-8', decode=None),
            expected_buf    = [u'**\u3042**\n', '\xe3\x81\x82', u'\n'],
            expected_errcls = UnicodeDecodeError,
            expected_errmsg = "'ascii' codec can't decode byte 0xe3 in position 0: ordinal not in range(128)"
         )
        ## decode binary into unicode in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode='utf-8'),
            expected_buf    = [u'**\u3042**\n', u'\u3042', u'\n'],
            expected_output = u"**あ**\nあ\n"
        )


if __name__ == '__main__':
    run(EncodingTest)
