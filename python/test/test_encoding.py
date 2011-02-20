# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
###

from oktest import ok, not_ok, run
import sys, os, re

from testcase_helper import *
import tenjin
from tenjin.helpers import *

lvars = "_extend=_buf.extend;_to_str=to_str;_escape=escape; "


class EncodingTest(object):


    def _test_render(self, template=None, to_str=None, encodings={},
                     expected_buf=None, expected_output=None,
                     expected_errcls=None, expected_errmsg=None):
        bkup = {
            'helpers.to_str': tenjin.helpers.to_str,
            'Template.tostrfunc': tenjin.Template.tostrfunc,
        }
        try:
            buf = []
            #encode = encodings.get('encode')
            #decode = encodings.get('decode')
            #if encode or decode:
            #    tenjin.set_template_encoding(encode=encode, decode=decode)
            #tenjin.Template.tostrfunc = staticmethod(to_str)
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
        finally:
            tenjin.helpers.to_str     = bkup['helpers.to_str']
            #tenjin.Template.tostrfunc = staticmethod(bkup['Template.tostrfunc'])

    def test_with_binary_template_and_binary_data(self):
        t = tenjin.Template()
        input = "**あ**\n#{'あ'}\n"
        script = lvars + "_extend(('''**\xe3\x81\x82**\n''', _to_str('\xe3\x81\x82'), '''\\n''', ));\n"
        ok (t.convert(input)) == script
        ## do nothing in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode=None),
            encodings       = dict(encode=None, decode=None),
            expected_buf    = ['**\xe3\x81\x82**\n', '\xe3\x81\x82', '\n'],
            expected_output = "**あ**\nあ\n"
        )
        ## encode unicode into binary in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode='utf-8', decode=None),
            encodings       = dict(encode='utf-8', decode=None),
            expected_buf    = ['**\xe3\x81\x82**\n', '\xe3\x81\x82', '\n'],
            expected_output = "**あ**\nあ\n"
        )
        ## decode binary into unicode in to_str()
        self._test_render(
            template        = t,
            to_str          = tenjin.generate_tostrfunc(encode=None, decode='utf-8'),
            encodings       = dict(encode=None, decode='utf-8'),
            expected_buf    = ['**\xe3\x81\x82**\n', u'\u3042', '\n'],
            expected_errcls = UnicodeDecodeError,
            expected_errmsg = "'ascii' codec can't decode byte 0xe3 in position 2: ordinal not in range(128)"
        )

    def test_with_unicode_template_and_binary_data(self):
        t = tenjin.Template(encoding='utf-8')
        input = "**あ**\n#{'あ'}\n"
        script = lvars + u"_extend((u'''**\u3042**\n''', _to_str('\u3042'), u'''\\n''', ));\n"
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
        script = lvars + "_extend(('''**\xe3\x81\x82**\n''', _to_str(u'\xe3\x81\x82'), '''\\n''', ));\n"
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
        script = lvars + u"_extend((u'''**\u3042**\n''', _to_str(u'\u3042'), u'''\\n''', ));\n"
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

    def test_set_template_encoding(self):
        assert tenjin.Template.encoding == None
        assert tenjin.helpers.to_str(u'日本語') == '日本語'
        assert tenjin.helpers.to_str('日本語') == '日本語'
        Template_encoding = tenjin.Template.encoding
        tenjin_to_str = tenjin.helpers.to_str
        try:
            tenjin.set_template_encoding('utf-8')
            ok (tenjin.Template.encoding) == 'utf-8'
            ok (tenjin.helpers.to_str(u'日本語')) == u'日本語'
            ok (tenjin.helpers.to_str('日本語')) == u'日本語'
            #ok (tenjin.Template().tostrfunc).is_(tenjin.helpers.to_str)
            #
            tenjin.set_template_encoding(encode='utf-8')
            ok (tenjin.Template.encoding) == None
            ok (tenjin.helpers.to_str(u'日本語')) == '日本語'
            ok (tenjin.helpers.to_str('日本語')) == '日本語'
            #ok (tenjin.Template().tostrfunc).is_(tenjin.helpers.to_str)
        finally:
            tenjin.Template.encoding = Template_encoding
            tenjin.helpers.to_str = tenjin_to_str

    def test_to_str_func_does_not_keep_escaped(self):
        from tenjin.escaped import EscapedStr, EscapedUnicode
        #
        to_str = tenjin.helpers.generate_tostrfunc(encode='utf-8')
        if "arg is str object then returns it as-is, keeping escaped.":
            ok (to_str('s')).is_a(str)
            not_ok (to_str('s')).is_a(EscapedStr)
            ok (to_str(EscapedStr('s'))).is_a(str)
            ok (to_str(EscapedStr('s'))).is_a(EscapedStr)
        if "arg is unicode object then encodes it into str, without keeping escaped.":
            ok (to_str(u's')).is_a(str)
            not_ok (to_str(u's')).is_a(EscapedStr)
            ok (to_str(EscapedUnicode(u's'))).is_a(str)
            not_ok (to_str(EscapedUnicode(u's'))).is_a(EscapedStr)
        #
        to_str = tenjin.helpers.generate_tostrfunc(decode='utf-8')
        if "arg is str object then decodes it into unicode, without keeping escaped.":
            ok (to_str('s')).is_a(unicode)
            not_ok (to_str('s')).is_a(EscapedUnicode)
            ok (to_str(EscapedStr('s'))).is_a(unicode)
            not_ok (to_str(EscapedStr('s'))).is_a(EscapedUnicode)
        if "arg is unicode object then returns it as-is, keeping escaped.":
            ok (to_str(u's')).is_a(unicode)
            not_ok (to_str(u's')).is_a(EscapedUnicode)
            ok (to_str(EscapedUnicode(u's'))).is_a(unicode)
            ok (to_str(EscapedUnicode(u's'))).is_a(EscapedUnicode)


if __name__ == '__main__':
    run()
