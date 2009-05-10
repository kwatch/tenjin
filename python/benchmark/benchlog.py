import sys, os, re

pattern = re.compile(r'^(\w[-\w]*)\s+([.\d]+)\s+([.\d]+)\s+([.\d]+)\s+([.\d]+)')

names = []
table = {}

for line in sys.stdin.readlines():
    m = pattern.match(line)
    if m:
        name, utime, stime, total, real = m.groups()
        #print name, utime, stime, total, real
        list = table.get(name)
        if not list:
            table[name] = list = []
            names.append(name)
        list.append((float(utime), float(stime), float(total), float(real), ))

print "                           utime      stime      total       real"
for name in names:
    tuples = table[name]
    utime = stime = total = real = 0.0
    for i, tuple in enumerate(tuples):
        utime += tuple[0]
        stime += tuple[1]
        total += tuple[2]
        real  += tuple[3]
    #print "%-21s %10.5f %10.5f %10.5f %10.5f" % (name, utime, stime, total, real)
    n = i + 1
    print "%-21s %7.2f000 %7.2f000 %7.2f000 %10.5f" % (name, utime/n, stime/n, total/n, real/n)
