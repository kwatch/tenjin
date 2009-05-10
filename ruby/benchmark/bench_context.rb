require 'yaml'

class StockInfo
  def initialize(values={})
    @name   = values['name']
    @name2  = values['name2']
    @url    = values['url']
    @symbol = values['symbol']
    @price  = values['price']
    @change = values['change']
    @ratio  = values['ratio']
  end
  attr_accessor :name, :name2, :url, :symbol, :price, :change, :ratio
end

ydoc = YAML.load_file('bench_context.yaml')
@list = ydoc['list'].collect { |values| StockInfo.new(values) }
