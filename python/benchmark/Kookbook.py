##
## this is a cookbook for PyKook.
## see http://www.kuwata-lab.com/kook  for details.
##

kook_default_product = 'all'

N = 10000

@cmdopts('-n N:  repeat N times in benchmark')
def task_all(c, *args):
    """do benchmark"""
    opts, rests = c.parse_cmdopts(args)
    n = opts.get('n') or N
    system(c%'python bench.py -n $(n)')

def task_clean(c):
    rm_rf('bench_django.*', 'bench_cheetah.*', 'bench_tenjin.*', 'bench_kid.*',
          'bench_myghty.*', 'bench_genshi.*', 'bench_mako*', 'bench_templetor.*')
    rm_rf('mako_modules')
