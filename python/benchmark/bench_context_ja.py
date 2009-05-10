import yaml

encoding = 'shift-jis'
filename = 'bench_context_ja.yaml'
input = open(filename).read().decode(encoding)
ydoc = yaml.load(input)

class StockInfo:
    def __init__(self, name, name2, url, symbol, price, change, ratio):
        self.name   = name
        self.name2  = name2
        self.url    = url
        self.symbol = symbol
        self.price  = price
        self.change = change
        self.ratio  = ratio

list = [StockInfo(**hash) for hash in ydoc['list']]

locals().pop('yaml')
locals().pop('encoding')
locals().pop('filename')
locals().pop('input')
locals().pop('ydoc')
locals().pop('hash')
locals().pop('StockInfo')
