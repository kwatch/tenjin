srcdir = "../../common/test"
kook_default_product = 'test'

import sys
python3 = sys.version_info[0] == 3
python2 = sys.version_info[0] == 2


@ingreds('test_engine.yaml', 'test_template.yaml')
def task_copy(c):
    """copy data file (*.yaml)"""
    pass


@product('test_*.yaml')
@ingreds(srcdir + '/test_$(1).yaml')
def file_test_engine_yaml(c):
    cp_p(c.ingred, c.product)


@ingreds('copy')
@byprods('test.log')
@cmdopts('-v: verbose')
def task_test(c, *args):
    options, rest = c.parse_cmdopts(args)
    opts = options.get('v') and ' -v ' or ''
    if python2:
        #system(c%'python test_all.py $(opts) 2>&1 | tee $(byprod)')
        system(c%'python test_all.py $(opts)')
        #system(c%'python test_all.py $(opts) 2>&1 > $(byprod)')
    elif python3:
        system(c%'python test_template.py $(opts)')
        system(c%'python test_engine.py $(opts)')
        system(c%'python test_main.py $(opts)')
        system(c%'python test_htmlhelper.py $(opts)')
        system(c%'python test_preprocess.py $(opts)')
    task_clean(c)


def task_clean(c):
    rm_f('test.log', '*.pyc', '**/*.pyc', '**/*.cache')
