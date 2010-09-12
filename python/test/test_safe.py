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



if __name__ == '__main__':
    run()
