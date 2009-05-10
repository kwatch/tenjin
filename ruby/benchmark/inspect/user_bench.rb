#!/usr/bin/env ruby

##
require 'optparse'
command = File.basename($0)
optparser = OptionParser.new
options = {}
['-h', '-n N', '-f file', '-l layout', '-p'].each do |opt|
  optparser.on(opt) { |val| options[opt[1].chr] = val }
end
begin
  filenames = optparser.parse!(ARGV)
rescue OptionParser::InvalidOption => ex
  $stderr.puts "#{command}: #{ex.to_s}"
  exit(1)
end

## help
if options['h']
    $stdout.print <<END
Usage: #{command} [-h] [-f datafile] [-n N] file1.epyc [file2.epyc ...]
  -h             :  show help
  -f datafile    :  context data file (*.py)
  -l layout      :  layout file
  -n N           :  N times to repeat in benchmark (default %d)
  -p             :  print output of evaluation
END
    exit(0)
end


## defalt values
ntimes = (options['n'] || 1000).to_i

## context data
require 'eryc'
context = Eryc::Context.new
datafile = options['f'] || 'user_context.rb'
s = File.read(datafile)
context.instance_eval(s, datafile)

#require 'pp';  pp context

layout = options['l']

## do benchmark
n = options['p'] ? 1 : ntimes
for filename in filenames
  manager = Eryc::Manager.new(:layout=>layout)
  start_t = Time.now()
  t1 = Process.times()
  output = nil
  if ! layout
    n.times do
      output = manager.evaluate(filename, context)
    end
  elsif layout == 'user_layout1.rbhtml'
    n.times do
      output = manager.evaluate_with_layout(filename, context)
    end
  elsif layout == 'user_layout2.rbhtml'
    n.times do
      _buf = []
      _buf = manager._evaluate_with_layout(filename, _buf, context)
      output = _buf.join()
    end
  else
    raise "#{layout}: unknown layout."
  end

  if options['p']
    print output
    next
  end

  t2 = Process.times()
  end_t = Time.now()

  ##
  utime = t2.utime - t1.utime
  stime = t2.stime - t1.stime
  real  = end_t - start_t
  printf "%10.5f %10.5f %10.5f\n" % [utime, stime, real]

end
