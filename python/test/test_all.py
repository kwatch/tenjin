###
### $Release:$
### $Copyright$
###


import sys
python3 = sys.version_info[0] == 3
python2 = sys.version_info[0] == 2


def main(verbose):

    basenames = [
        "test_template",
        "test_engine",
        "test_preprocess",
        "test_htmlhelper",
        "test_main",
        "test_encoding",
        "test_users_guide",
        "test_faq",
        "test_examples",
    ]
    if python3:
        basenames.remove("test_encoding")

    if verbose:

        import os
        for basename in basenames:
            print('')
            print("************************************************* " + basename)
            os.system("python %s.py" % basename)

    else:

        import unittest
        from oktest import ok, not_ok
        suite = unittest.TestSuite()
        for basename in basenames:
            test_module = __import__(basename)
            suite.addTest(unittest.findTestCases(test_module))

        unittest.TextTestRunner(verbosity=1).run(suite)
        #unittest.TextTestRunner(verbosity=2).run(test_template.TemplateTest)



if __name__ == '__main__':

    import sys
    verbose = len(sys.argv) > 1 and sys.argv[1] == '-v'
    main(verbose)
    sys.exit(0)
