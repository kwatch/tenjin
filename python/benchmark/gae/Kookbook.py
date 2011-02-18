from __future__ import with_statement

import sys, re, os

kook_default_product = 'all'

generatable_products = (
    'templates/bench_django.html',
    #'templates/escape_django.html',
    'templates/bench_django12.html',
    'templates/escape_django12.html',
    'templates/bench_tenjin.pyhtml',
    #'templates/escape_tenjin.pyhtml',
    'templates/bench_safetenjin.pyhtml',
    'templates/escape_safetenjin.pyhtml',
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
@ingreds("lib/tenjin.py")
@spices("-p port: port number (default 8080)")
def server(c, *args, **kwargs):
    """invoke dev_appserver.py"""
    port = kwargs.get('p', 8080)
    script = "/usr/local/google_appengine/dev_appserver.py"
    system(c%"python $(script) -p $(port) .")


@recipe
@product("lib/tenjin.py")
@ingreds("../../lib2/tenjin.py")
def file_tenjin_py(c):
    """copy tenjin.py into lib directory"""
    if not os.path.isdir("lib"):
        mkdir("lib")
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
@product('templates/bench_mako.html')
@ingreds('templates/escape_mako.html')
def file_bench_mako_html(c):
    f = lambda s: s.replace('|h}', '}').replace('escape_mako', 'bench_mako')
    convert_template(c, f)


@recipe
@product('templates/bench_jinja2.html')
@ingreds('templates/escape_jinja2.html')
def file_bench_mako_html(c):
    f = lambda s: s.replace('escape_jinja2', 'bench_jinja2')
    convert_template(c, f)


@recipe
@product('templates/bench_tenjin.pyhtml')
@ingreds('templates/escape_tenjin.pyhtml')
def file_escape_tenjin_pyhtml(c):
    f = lambda s: s.replace('${', '#{').replace('escape_tenjin', 'bench_tenjin')
    convert_template(c, f)


@recipe
@product('templates/bench_safetenjin.pyhtml')
@ingreds('templates/escape_tenjin.pyhtml')
def file_bench_safetenjin_pyhtml(c):
    def f(s):
        s = re.sub(r'\$\{(.*?)\}', r'{==\1==}', s)
        return s.replace('escape_tenjin', 'bench_safetenjin')
    convert_template(c, f)


@recipe
@product('templates/escape_safetenjin.pyhtml')
@ingreds('templates/escape_tenjin.pyhtml')
def file_escape_safetenjin_pyhtml(c):
    def f(s):
        s = re.sub(r'\$\{(.*?)\}', r'{=\1=}', s)
        return s.replace('escape_tenjin', 'escape_safetenjin')
    convert_template(c, f)
