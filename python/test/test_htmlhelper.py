# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
###

from oktest import ok, not_ok, run
import sys, os, re

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

from testcase_helper import *
import tenjin
from tenjin.helpers import escape, to_str
from tenjin.html import *

if python2:
    from tenjin.escaped import as_escaped, EscapedStr, EscapedUnicode
    def u(s):
        return s.decode('utf-8')
else:
    from tenjin.escaped import as_escaped, EscapedStr, EscapedBytes
    def u(s):
        return s


class HtmlHelperTest(object):

    def test_escape_html(self):
        ok (escape_html('<>&"\'')) == '&lt;&gt;&amp;&quot;&#39;'
        ok (escape_html('[SOS]')) == '[SOS]'
        def f(): escape_html(123)
        #ok (f).raises(Exception)
        ok (f).raises(AttributeError, "'int' object has no attribute 'replace'")

    def test_tagattr(self):
        ok (tagattr('size', 20))           == ' size="20"'
        ok (tagattr('size', 0))            == ' size="0"'
        ok (tagattr('size', ''))           == ''
        ok (tagattr('size', 20, 'large'))  == ' size="large"'
        ok (tagattr('size',  0, 'zero'))   == ' size="zero"'
        ok (tagattr('size', '', 'empty'))  == ''
        ok (tagattr('title', '<>&"'))      == ' title="&lt;&gt;&amp;&quot;"'
        ok (tagattr('title', '<>&"', escape=False)) == ' title="<>&""'
        #
        ok (tagattr('size', 20)).is_a(EscapedStr)
        ok (tagattr('size', '')).is_a(EscapedStr)

    def test_tagattrs(self):
        ok (tagattrs(src="img.png", size=20)) == ' src="img.png" size="20"'
        ok (tagattrs(src='', size=0))         == ' size="0"'
        ok (tagattrs(klass='error'))          == ' class="error"'    # klass='error' => class="error"
        ok (tagattrs(checked='Y'))            == ' checked="checked"'
        ok (tagattrs(selected=1))             == ' selected="selected"'
        ok (tagattrs(disabled=True))          == ' disabled="disabled"'
        ok (tagattrs(checked='', selected=0, disabled=None)) == ''
        #
        ok (tagattrs(size=20)).is_a(EscapedStr)
        ok (tagattrs(size=None)).is_a(EscapedStr)
        #
        ok (tagattrs(name="<foo>"))    == ' name="&lt;foo&gt;"'
        ok (tagattrs(name=u("<foo>"))) == ' name="&lt;foo&gt;"'
        ok (tagattrs(name=as_escaped("<foo>")))    == ' name="<foo>"'
        ok (tagattrs(name=as_escaped(u("<foo>")))) == ' name="<foo>"'

    def test_checked(self):
        ok (checked(1==1)) == ' checked="checked"'
        ok (checked(1==0)) == ''
        #
        ok (checked(1==1)).is_a(EscapedStr)
        ok (checked(1==0)).is_a(EscapedStr)

    def test_selected(self):
        ok (selected(1==1)) == ' selected="selected"'
        ok (selected(1==0)) == ''
        #
        ok (selected(1==1)).is_a(EscapedStr)
        ok (selected(1==0)).is_a(EscapedStr)

    def test_disabled(self):
        ok (disabled(1==1)) == ' disabled="disabled"'
        ok (disabled(1==0)) == ''
        #
        ok (disabled(1==1)).is_a(EscapedStr)
        ok (disabled(1==0)).is_a(EscapedStr)

    def test_nl2br(self):
        s = """foo\nbar\nbaz\n"""
        ok (nl2br(s)) == "foo<br />\nbar<br />\nbaz<br />\n"
        #
        ok (nl2br(s)).is_a(EscapedStr)

    def test_text2html(self):
        s = """FOO\n    BAR\nBA     Z\n"""
        expected = "FOO<br />\n &nbsp; &nbsp;BAR<br />\nBA &nbsp; &nbsp; Z<br />\n"
        ok (text2html(s)) == expected
        expected = "FOO<br />\n    BAR<br />\nBA     Z<br />\n"
        ok (text2html(s, False)) == expected
        #
        ok (text2html(s)).is_a(EscapedStr)

    def test_nv(self):
        ok (nv('rank', 'A'))       == 'name="rank" value="A"'
        ok (nv('rank', 'A', '.'))  == 'name="rank" value="A" id="rank.A"'
        ok (nv('rank', 'A', klass='error')) == 'name="rank" value="A" class="error"'
        ok (nv('rank', 'A', checked=True))  == 'name="rank" value="A" checked="checked"'
        ok (nv('rank', 'A', disabled=10))   == 'name="rank" value="A" disabled="disabled"'
        ok (nv('rank', 'A', style="color:red")) == 'name="rank" value="A" style="color:red"'
        #
        ok (nv('rank', 'A')).is_a(EscapedStr)
        #
        #ok (nv(u("名前"), u("なまえ"))) == u('name="名前" value="なまえ"')
        ok (nv(u("名前"), u("なまえ"))) == 'name="名前" value="なまえ"'
        if python2:
            ok (nv(u("名前"), u("なまえ"))).is_a(EscapedStr)  # not EscapedUnicode!

    def test_js_link(self):
        html = js_link("<b>SOS</b>", "alert('Haru&Kyon')")
        ok (html) == '''<a href="javascript:undefined" onclick="alert(&#39;Haru&amp;Kyon&#39;);return false">&lt;b&gt;SOS&lt;/b&gt;</a>'''
        #
        html = js_link(as_escaped("<b>SOS</b>"), as_escaped("alert('Haru&Kyon')"))
        ok (html) == '''<a href="javascript:undefined" onclick="alert('Haru&Kyon');return false"><b>SOS</b></a>'''
        #
        html = js_link("<b>SOS</b>", "alert('Haru&Kyon')", klass='<sos2>')
        ok (html) == '''<a href="javascript:undefined" onclick="alert(&#39;Haru&amp;Kyon&#39;);return false" class="&lt;sos2&gt;">&lt;b&gt;SOS&lt;/b&gt;</a>'''



if __name__ == '__main__':
    run()
