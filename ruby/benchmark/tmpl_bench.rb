## parse options
require 'optparse'
optparser = OptionParser.new()
options = {}
['-h', '-p', '-n N', '-t targets', '-x exclude'].each do |opt|
  optparser.on(opt) { |val| options[opt[1].chr] = val }
end
begin
  filenames = optparser.parse!(ARGV)
rescue => ex
  $stderr.puts "#{command}: #{ex.to_s}"
  exit(1)
end

## defaults
ntimes = 1000
targets = 'eruby,eruby-cache,erb,erb-cache,erb-reuse,eryc,eryc-cache,eryc-reuse'
targets_all = targets + ',eryc-tmpl,eryc-defun,eryc-defun-reuse'

## help
if options['h']
  puts "Usage: python %s [-h] [-n N] [-t targets] > /dev/null" % command
  puts "  -h         :  help"
  #puts "  -p         :  print output"
  puts "  -n N       :  loop N times (default %d)" % ntime
  puts "  -t targets :  target names (default: '%s')" % targets
  puts "  -x exclude :  excluded target name"
  sys.exit(0)
end

## set parameters
ntimes = options.fetch('n', ntimes).to_i
if options['t'] && options['t'].upcase == 'ALL'
  targets = targets_all.split(',')
else
  targets = options.fetch('t', targets).split(',')
end
exclude = options['x']
targets.delete(exclude) if exclude

## require libraries
require 'erb'
require 'eryc'
begin
  require 'eruby'
rescue LoadError
  ERuby = nil
end
require 'cgi'
include ERB::Util

## context data
context = Eryc::Context.new
datafile = 'tmpl_context.rb'
context.instance_eval(File.read(datafile), datafile)
s = ''
context.instance_variables.each do |varname|
  name = varname[1..-1]
  s << "#{name} = context[#{name.inspect}]\n"
end
bindobj = nil
s << "bindobj = binding()\n"
eval s
#eval "puts '** title='+title\n"            # error on 1.9
#eval "puts '** title='+title\n", bindobj   # ok

## helper methods
def msg(message)
  $stdout.write(message)
  $stdout.flush()
end

def defun_code(rbcode)
  return <<-END
      def tmpl_eryc_view()
        _buf = ''
        _tmpl_eryc_view(_buf)
        return _buf
      end
      def _tmpl_eryc_view(_buf)
#{rbcode}
      end
  END
end


def read_and_convert(filename, &block)
  cachename = filename + '.cache'
  if !test(?f, cachename) || File.mtime(cachename) < File.mtime(filename)
    rbcode = yield(filename)
    File.open(cachename, 'w') { |f| f.write(rbcode) }
  else
    rbcode = File.read(cachename)
  end
  return rbcode
end


## preparation
#msg('----- start benchmark preparations.\n')
#msg('----- end benchmark preparations.\n\n')

## benchmark
if options['p']
  ntimes = 1
else
  $stderr.puts "          target     utime      stime      total      real"
end
for target in targets
  GC.start()
  start_t = Time.now()
  t1 = Process.times()

  case target
  when 'eruby'
    ntimes.times do
      ERuby.import('tmpl_eruby.rhtml')
    end if ERuby
  when 'eruby-cache'
    ntimes.times do
      rbcode = read_and_convert('tmpl_eruby.rhtml') do |fname|
        ERuby::Compiler.new.compile_string(File.read(fname))
      end
      eval rbcode, bindobj
    end if ERuby
  when 'erb'
    ntimes.times do
      erb = ERB.new(File.read('tmpl_erb.rhtml'))
      output = erb.result(bindobj)
      print output
    end
  when 'erb-cache'
    ntimes.times do
      rbcode = read_and_convert('tmpl_erb.rhtml') do |fname|
        ERB.new(File.read(fname)).src
      end
      output = eval rbcode, bindobj
      print output
    end
  when 'erb-reuse'
    erb = ERB.new(File.read('tmpl_erb.rhtml'))
    ntimes.times do
      output = erb.result(bindobj)
      print output
    end
  when 'eryc-tmpl'
    ntimes.times do
      template = Eryc::Template.new('tmpl_eryc.rbhtml')
      output = template.evaluate(context)
      print output
    end
  when 'eryc'
    ntimes.times do
      manager = Eryc::Manager.new(:cache=>false)
      output = manager.evaluate('tmpl_eryc.rbhtml', context)
      print output
    end
  when 'eryc-cache'
    ntimes.times do
      manager = Eryc::Manager.new(:cache=>true)
      output = manager.evaluate('tmpl_eryc.rbhtml', context)
      print output
    end
  when 'eryc-reuse'
    manager = Eryc::Manager.new()
    ntimes.times do
      output = manager.evaluate('tmpl_eryc.rbhtml', context)
      print output
    end
  when 'eryc-defun'
    template = Eryc::Template.new('tmpl_eryc.rbhtml')
    defun = defun_code(template.rbcode)
    ntimes.times do
      context.instance_eval(defun)
      output = context.tmpl_eryc_view()
      print output
    end
  when 'eryc-defun-reuse'
    template = Eryc::Template.new('tmpl_eryc.rbhtml')
    defun = defun_code(template.rbcode)
    context.instance_eval(defun)
    ntimes.times do
      output = context.tmpl_eryc_view()
      print output
    end
  else
    sys.stderr.write("*** %s: invalid target.\n" % target)
    sys.exit(1)
  end

  t2 = Process.times()
  end_t = Time.now()

  if options['p']
    #File.open('%s.result' % target, 'w') { |f| write(output) } unless target == 'eruby'
    #puts 'created: %s.result' % target
    next
  end

  ## result
  d = 4
  utime = t2[0]-t1[0]
  stime = t2[1]-t1[1]
  total = utime + stime
  real  = end_t-start_t
  $stderr.puts "%16s  %10.5f %10.5f %10.5f %10.5f" % [target, utime, stime, total, real]

end
