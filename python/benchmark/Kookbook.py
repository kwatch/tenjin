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
