###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
###


import sys, os, glob
python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3


def main(verbose):

    basenames = [
        "test_template",
        "test_engine",
        "test_preprocessor",
        "test_safe",
        "test_htmlhelper",
        "test_main",
        "test_encoding",
        "test_loader",
        "test_store",
        "test_gae",
        "test_tenjin",
        "test_users_guide",
        "test_examples",
    ]
    #filenames = glob.glob(os.path.dirname(__file__) + '/test_*.py')
    #assert len(filenames) - 1 == len(basenames)

    if python3:
        basenames.remove("test_encoding")
        basenames.remove("test_gae")
    if python2 and sys.version_info[1] <= 4:
        basenames.remove("test_gae")

    if verbose:

        for basename in basenames:
            print('')
            print("************************************************* " + basename)
            os.system("%s %s.py" % (sys.executable, basename))

    else:

        #import unittest
        #from oktest import ok, not_ok
        #suite = unittest.TestSuite()
        #for basename in basenames:
        #    test_module = __import__(basename)
        #    suite.addTest(unittest.findTestCases(test_module))
        #
        #unittest.TextTestRunner(verbosity=1).run(suite)
        ##unittest.TextTestRunner(verbosity=2).run(test_template.TemplateTest)
        test_classes = []
        for basename in basenames:
            test_module = __import__(basename)
            for x in dir(test_module):
                if x.endswith('Test'):
                    klass = getattr(test_module, x)
                    if type(klass) == type:
                        test_classes.append(klass)
        import oktest
        kwd = {'style': 'simple'}
        oktest.run(*test_classes, **kwd)



if __name__ == '__main__':

    import sys
    verbose = len(sys.argv) > 1 and sys.argv[1] == '-v'
    main(verbose)
    sys.exit(0)
