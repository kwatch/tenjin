class OrderedHash < Hash

  def initialize(*args)
    super
    @keys = []
  end

  def []=(key, val)
    @keys << key unless self.key?(key)
    super
  end

  def keys
    return @keys.dup
  end

  def values
    return @keys.collect {|k| self[k] }
  end

  def each
    @keys.each do |key|
      val = self[key]
      yield key, val
    end
  end

end

table = OrderedHash.new

while line = gets()
  if line =~ /^(\w[-\w]*)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+\(\s*([\d.]+)\)/
    (table[$1] ||= []) << [$2, $3, $4, $5]
  end
end

result = OrderedHash.new

puts "%-19s %10s %10s %10s  %10s" % [' ', 'user', 'system', 'total', 'real']
for name, tuples in table
  #puts "*** #{name}"
  utime = stime = total = real = 0
  for tuple in tuples
    #puts "%s, %s, %s, %s" % tuple
    utime += tuple[0].to_f
    stime += tuple[1].to_f
    total += tuple[2].to_f
    real  += tuple[3].to_f
  end
  #result[name] = [utime, stime, total, real]
  #puts "%-19s %10.5f %10.5f %10.5f (%10.5f)" % ([name] + result[name])
  result[name] = [utime/10, stime/10, total/10, real/10]
  puts "%-19s %7.2f000 %7.2f000 %7.2f000 (%10.5f)" % ([name] + result[name])
end
