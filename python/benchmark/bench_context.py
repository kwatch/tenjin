import yaml

ydoc = yaml.load(open('bench_context.yaml'))

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
locals().pop('ydoc')
locals().pop('hash')
locals().pop('StockInfo')
