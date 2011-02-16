from __future__ import with_statement

kook_default_product = 'all'

generatable_products = (
    'templates/bench_django.html',
    'templates/bench_django12.html',
    'templates/escape_django12.html',
    'templates/bench_tenjin.pyhtml',
)

@recipe
@ingreds('tenjin.py', *generatable_products)
def task_all(c):
    """copy tenjin.py and generates template files"""
    pass


@recipe
def task_clean(c):
    """clean generated files."""
    rm_f(generatable_products)


@recipe
@product('tenjin.py')
@ingreds('../../lib/tenjin.py')
def file_tenjin_py(c):
    cp_p(c.ingred, c.product)


def convert_template(c, func):
    with open(c.ingred, 'rb') as f:
        s = f.read()
    s = func(s)
    with open(c.product, 'wb') as f:
        f.write(s)


@recipe
@product('templates/bench_django.html')
@ingreds('templates/escape_django.html')
def file_bench_django_html(c):
    f = lambda s: s.replace('|escape', '').replace('escape_django', 'bench_django')
    convert_template(c, f)


@recipe
@product('templates/bench_django12.html')
@ingreds('templates/escape_django.html')
def file_bench_django12_html(c):
    f = lambda s: s.replace('|escape', '|safe').replace('escape_django', 'bench_django12')
    convert_template(c, f)


@recipe
@product('templates/escape_django12.html')
@ingreds('templates/escape_django.html')
def file_escape_django12_html(c):
    f = lambda s: s.replace('|escape', '').replace('escape_django', 'escape_django12')
    convert_template(c, f)


@recipe
@product('templates/bench_tenjin.pyhtml')
@ingreds('templates/escape_tenjin.pyhtml')
def file_escape_tenjin_pyhtml(c):
    f = lambda s: s.replace('${', '#{').replace('escape_tenjin', 'bench_tenjin')
    convert_template(c, f)
