###
### $Rev$
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
        self.assertEquals('src="img.png" size="20"', tagattr(src="img.png", size=20))
        self.assertEquals('',                        tagattr(src='', size=0))
        self.assertEquals('class="error"',           tagattr(klass='error'))

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
        self.assertEqual('name="rank" value="A"',                   nv('rank', 'A'))
        self.assertEqual('name="rank" value="A" id="rank.A"',       nv('rank', 'A', '.'))
        self.assertEqual('name="rank" value="A" checked="checked"', nv('rank', 'A', checked=True))


if __name__ == '__main__':
    unittest.main()
