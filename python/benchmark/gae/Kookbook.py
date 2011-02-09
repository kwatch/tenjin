from __future__ import with_statement

kook_default_product = 'all'

@recipe
@ingreds('tenjin.py',
         'templates/bench_django.html',
         'templates/bench_tenjin.pyhtml')
def task_all(c):
    """copy tenjin.py and generates template files"""
    pass


@recipe
@product('tenjin.py')
@ingreds('../../lib/tenjin.py')
def file_tenjin_py(c):
    cp_p(c.ingred, c.product)


@recipe
@product('templates/bench_django.html')
@ingreds('templates/escape_django.html')
def file_bench_django_html(c):
    with open(c.ingred, 'rb') as f:
        s = f.read()
    s = s.replace('|escape', '').replace('escape_django', 'bench_django')
    with open(c.product, 'wb') as f:
        f.write(s)


@recipe
@product('templates/bench_tenjin.pyhtml')
@ingreds('templates/escape_tenjin.pyhtml')
def file_escape_tenjin_pyhtml(c):
    with open(c.ingred, 'rb') as f:
        s = f.read()
    s = s.replace('${', '#{').replace('escape_tenjin', 'bench_tenjin')
    with open(c.product, 'wb') as f:
        f.write(s)
