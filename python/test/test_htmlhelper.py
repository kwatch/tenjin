###
### $Release:$
### $Copyright$
###

import unittest
import sys, os, re

from testcase_helper import *
import tenjin
from tenjin.helpers import escape, to_str


class HtmlHelperTest(unittest.TestCase, TestCaseHelper):

    def test_tagattr(self):
        tagattr = tenjin.helpers.html.tagattr
        self.assertEquals(' size="20"',     tagattr('size', 20))
        self.assertEquals('',               tagattr('size', 0))
        self.assertEquals(' size="large"',  tagattr('size', 20, 'large'))
        self.assertEquals('',               tagattr('size', 0, 'zero'))
        self.assertEquals(' title="&lt;&gt;&amp;&quot;"', tagattr('title', '<>&"'))

    def test_tagattrs(self):
        tagattrs = tenjin.helpers.html.tagattrs
        self.assertEquals('src="img.png" size="20"', tagattrs(src="img.png", size=20))
        self.assertEquals('',                        tagattrs(src='', size=0))
        self.assertEquals('class="error"',           tagattrs(klass='error'))    # klass='error' => class="error"

    def test_checked(self):
        checked = tenjin.helpers.html.checked
        self.assertEqual(' checked="checked"', checked(1==1))
        self.assertEqual('',                   checked(1==0))

    def test_selected(self):
        selected = tenjin.helpers.html.selected
        self.assertEqual(' selected="selected"', selected(1==1))
        self.assertEqual('',                     selected(1==0))

    def test_disabled(self):
        disabled = tenjin.helpers.html.disabled
        self.assertEqual(' disabled="disabled"', disabled(1==1))
        self.assertEqual('',                     disabled(1==0))

    def test_nl2br(self):
        nl2br = tenjin.helpers.html.nl2br
        s = """foo\nbar\nbaz\n"""
        self.assertEqual("foo<br />\nbar<br />\nbaz<br />\n", nl2br(s))

    def test_text2html(self):
        text2html = tenjin.helpers.html.text2html
        s = """FOO\n    BAR\nBA     Z\n"""
        expected = "FOO<br />\n &nbsp; &nbsp;BAR<br />\nBA &nbsp; &nbsp; Z<br />\n"
        self.assertEqual(expected, text2html(s))

    def test_nv(self):
        nv = tenjin.helpers.html.nv
        self.assertEqual('name="rank" value="A"',              nv('rank', 'A'))
        self.assertEqual('name="rank" value="A" id="rank.A"',  nv('rank', 'A', '.'))
        self.assertEqual('name="rank" value="A" class="error"',
                         nv('rank', 'A', klass='error'))
        self.assertEqual('name="rank" value="A" checked="checked"',
                         nv('rank', 'A', checked=True))
        self.assertEqual('name="rank" value="A" disabled="disabled"',
                         nv('rank', 'A', disabled=10))
        self.assertEqual('name="rank" value="A" style="color:red"',
                         nv('rank', 'A', style="color:red"))

    def test_new_cycle(self):
        cycle = tenjin.helpers.html.new_cycle('odd', 'even')
        self.assertEqual('odd',  cycle())
        self.assertEqual('even', cycle())
        self.assertEqual('odd',  cycle())
        self.assertEqual('even', cycle())
        #
        cycle = tenjin.helpers.html.new_cycle('A', 'B', 'C')
        self.assertEqual('A', cycle())
        self.assertEqual('B', cycle())
        self.assertEqual('C', cycle())
        self.assertEqual('A', cycle())
        self.assertEqual('B', cycle())
        self.assertEqual('C', cycle())


remove_unmatched_test_methods(HtmlHelperTest)


if __name__ == '__main__':
    unittest.main()
