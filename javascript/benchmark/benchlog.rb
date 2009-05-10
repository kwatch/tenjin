
names = []
table = {}

name = nil
while line = gets()
  if line =~ /^time .* bench.js -n \d+( +(\S+))?/
    name = $2
  elsif line =~ /([.\d]+) real\s+([.\d]+) user\s+([.\d]+) sys/
    names << name unless table[name]
    (table[name] ||= []) << [$1.to_f, $2.to_f, $3.to_f]
  end
end

result = {}

#puts "%-19s %10s %10s %10s  %10s" % [' ', 'user', 'system', 'total', 'real']
for name in names
  tuples = table[name]
  real = utime = stime = 0.0
  for tuple in tuples
    real  += tuple[0]
    utime += tuple[1]
    stime += tuple[2]
  end
  puts "%-19s %10.4f %10.4f %10.4f" % [name, utime, stime, real]
  #puts "%-19s %7.2f000 %7.2f000 %7.2f000" % [name, utime, stime, real]
end
