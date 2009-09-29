##
## this is a cookbook for PyKook.
## see http://www.kuwata-lab.com/kook/  for details.
##

names = "tenjin django cheetah kid myghty genshi mako templetor jinja2".split(' ')
kook_default_product = 'all'

N = 10000

@recipe
@spices('-n N:  repeat N times in benchmark')
def task_all(c, *args):
    """do benchmark"""
    opts, rests = c.parse_cmdopts(args)
    n = opts.get('n') or N
    system(c%'python bench.py -n $(n)')

@recipe
def task_clean(c):
    rm_rf(['bench_%s.*' % name for name in names])
    rm_rf(['%s.result'  % name for name in names])
    rm_rf('mako_modules')



@recipe
@product("bench_context.py")
def file_bench_context_py(c):
    """create context data file *.py from *.yaml"""
    import yaml
    ydoc = yaml.load(open('bench_context.yaml'))
    buf = []
    buf.append("items = [\n")
    for item in ydoc['list']:
        buf.extend((
            "    {\n",
            "        'name':   %s,\n" % repr(item['name']),
            "        'name2':  %s,\n" % repr(item['name2']),
            "        'url':    %s,\n" % repr(item['url']),
            "        'symbol': %s,\n" % repr(item['symbol']),
            "        'price':   %s,\n" % (item['price']),
            "        'change':  %s,\n" % (item['change']),
            "        'ratio':   %s,\n" % (item['ratio']),
            "    },\n",
            ))
    buf.append("]\n")
    buf.append("\n")
    buf.append("""
class StockInfo:
    def __init__(self, name, name2, url, symbol, price, change, ratio):
        self.name   = name
        self.name2  = name2
        self.url    = url
        self.symbol = symbol
        self.price  = price
        self.change = change
        self.ratio  = ratio

items2 = [StockInfo(**item) for item in items]
""")
    import kook.utils
    kook.utils.write_file(c.product, ''.join(buf))
