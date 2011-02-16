
import sys, os, re
python3 = sys.version_info[0] == 3
python2 = sys.version_info[0] == 2

srcdir = re.sub(r'/tenjin.*$', r'/tenjin/common/test', os.getcwd())
kook_default_product = 'test'


@recipe
@ingreds('test_engine.yaml', 'test_template.yaml')
def task_copy(c):
    """copy data file (*.yaml)"""
    pass


@recipe
@product('test_*.yaml')
@ingreds(srcdir + '/test_$(1).yaml.eruby')
def file_test_engine_yaml(c):
    os.environ['RUBYLIB'] = ''
    system(c%"erubis -E PercentLine -p '%%%%%%= =%%%%%' -c '@lang=%q|python|' $(ingred) > $(product)")
    #cp_p(c.ingred, c.product)


@recipe
@ingreds('copy')
@byprods('test.log')
@spices('-v: verbose')
def task_test(c, *args):
    options, rest = c.parse_cmdopts(args)
    opts = options.get('v') and ' -v ' or ''
    system(c%'python test_all.py $(opts)')
    #if python2:
    #    #system(c%'python test_all.py $(opts) 2>&1 | tee $(byprod)')
    #    system(c%'python test_all.py $(opts)')
    #    #system(c%'python test_all.py $(opts) 2>&1 > $(byprod)')
    #elif python3:
    #    unsupported_tests = ['test_all.py', 'test_users_guide.py', 'test_faq.py',
    #                         'test_examples.py', 'test_encoding.py', 'test_gae.py', ]
    #    from glob import glob
    #    for x in glob('test_*.py'):
    #        if x not in unsupported_tests:
    #            system(c%'python $(x) $(opts)')
    #    #system(c%'python test_template.py $(opts)')
    #    #system(c%'python test_engine.py $(opts)')
    #    #system(c%'python test_main.py $(opts)')
    #    #system(c%'python test_htmlhelper.py $(opts)')
    #    #system(c%'python test_preprocess.py $(opts)')
    task_clean(c)


@recipe
def task_clean(c):
    rm_f('test.log', '*.pyc', '**/*.pyc', '**/*.cache')
