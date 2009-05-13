srcdir = "../../../rbtenjin/trunk/test"
kook_default_product = 'test'


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
    #system(c%'python test_all.py $(opts) 2>&1 | tee $(byprod)')
    system(c%'python test_all.py $(opts)')
    #system(c%'python test_all.py $(opts) 2>&1 > $(byprod)')
    task_clean(c)


def task_clean(c):
    rm_f('test.log', '*.pyc', '**/*.pyc', '**/*.cache')
