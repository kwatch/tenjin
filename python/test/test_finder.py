###
### $Release:$
### $Copyright$
###

from oktest import ok, not_ok, run, spec
import sys, os, time
import tenjin

from test_engine import _with_dummy_files


class FileFinderTest(object):

    def before(self):
        self.finder = tenjin.FileFinder()
        self.dirs = ['_views/blog', '_views']

    @_with_dummy_files
    def test_find(self):
        if spec("if dirs provided then search template file from it."):
            ok (self.finder.find('index.pyhtml', self.dirs)) == '_views/blog/index.pyhtml'
            ok (self.finder.find('layout.pyhtml', self.dirs)) == '_views/layout.pyhtml'
        if spec("if dirs not provided then just return filename if file exists."):
            ok (self.finder.find('_views/index.pyhtml')) == '_views/index.pyhtml'
        if spec("if file not found then return None."):
            ok (self.finder.find('index2.pyhtml', self.dirs)) == None
            ok (self.finder.find('index2.pyhtml')) == None

    @_with_dummy_files
    def test_abspath(self):
        if spec("return full-path of filepath"):
            ret = self.finder.abspath('_views/blog/index.pyhtml')
            ok (ret) == os.path.join(os.getcwd(), '_views/blog/index.pyhtml')

    @_with_dummy_files
    def test_timestamp(self):
        if spec("return mtime of file"):
            ts = float(int(time.time())) - 3.0
            os.utime('_views/blog/index.pyhtml', (ts, ts))
            ret = self.finder.timestamp('_views/blog/index.pyhtml')
            ok (ret) == ts

    @_with_dummy_files
    def test_read(self):
        if spec("if file exists, return file content and mtime"):
            ts = float(int(time.time())) - 1.0
            os.utime('_views/layout.pyhtml', (ts, ts))
            ret = self.finder.read('_views/layout.pyhtml')
            ok (ret) == ("<div>#{_content}</div>", ts)
        if spec("if file not exist, return None"):
            ret = self.finder.read('_views/layout2.pyhtml')
            ok (ret) == None


if __name__ == '__main__':
    run()
