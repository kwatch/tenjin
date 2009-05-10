## parse options
require 'optparse'
optparser = OptionParser.new()
options = {}
['-h', '-p', '-n N', '-e', '-q', '-A', '-f file', '-m mode', '-x exclude'].each do |opt|
  optparser.on(opt) { |val| options[opt[1].chr] = val }
end
begin
  filenames = optparser.parse!(ARGV)
rescue => ex
  command = File.basename($0)
  $stderr.puts "#{command}: #{ex.to_s}"
  exit(1)
end


## defaults
ntimes = 1000
mode = 'class'     # 'class' or 'hash'
escape = options['e']
targets = %w[eruby eruby-cache erb erb-cache erb-reuse erb-defmethod erubis erubis-cache erubis-reuse tenjin tenjin-nocache tenjin-reuse]
#targets_all = targets + %w[tenjin-tmpl tenjin-defun tenjin-defun-reuse] + %w[eruby-convert erb-convert erubis-convert tenjin-convert]
targets_all = targets + %w[tenjin-arrbuf tenjin-arrbuf-nocache tenjin-arrbuf-reuse]


## help
if options['h']
  command = File.basename($0)
  puts "Usage: ruby %s [-h] [-n N] [targets] " % command
  puts "  -h         :  help"
  #puts "  -p         :  print output"
  puts "  -n N       :  loop N times (default %d)" % ntimes
  puts "  -f file    :  context data file"
  puts "  -x exclude :  excluded target name"
  puts "  -q         :  quiet mode"
  puts "  -m mode    :  'class' or 'hash' (default '%s')" % mode
  puts "  -e         :  escape html"
  exit(0)
end


## set parameters
ntimes = options.fetch('n', ntimes).to_i
mode = options.fetch('m', mode)
$quiet = options['q']
datafile = options['f']
unless datafile
  if mode == 'class'
    datafile = 'bench_context.rb'
  elsif mode == 'hash'
    datafile = 'bench_context.yaml'
  else
    assert unreachable
  end
end
if options['A']
  targets = targets_all
elsif filenames && !filenames.empty?
  if filenames[0] =~ /^\/.*\/$/
    regexp = eval filenames[0]
    targets = targets_all.select { |t| t =~ regexp }
  else
    targets = filenames
  end
end
exclude = options['x']
targets.delete(exclude) if exclude


## require libraries
require 'erb'
require 'tenjin'
begin
  require 'eruby'
rescue LoadError
  ERuby = nil
end
begin
  require 'erubis'
rescue LoadError
  Erubis = nil
end
require 'cgi'
include ERB::Util


## context data
if datafile =~ /\.rb$/
  context = Tenjin::Context.new
  context.instance_eval(File.read(datafile), datafile)
elsif datafile =~ /\.ya?ml$/
  require 'yaml'
  ydoc = YAML.load_file(datafile)
  context = Tenjin::Context.new(ydoc)
end
if escape
  context[:list].each do |item|
    if item.name =~ / /
      item.name = "<#{item.name.gsub(/ /, '&')}>"
    else
      item.name = "\"#{item.name}\""
    end
  end
end
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
  unless $quiet
    $stdout.write(message)
    $stdout.flush()
  end
end


def defun_code(rbcode)
  return <<-END
      def tmpl_tenjin_view()
        _buf = ''
        _tmpl_tenjin_view(_buf)
        return _buf
      end
      def _tmpl_tenjin_view(_buf)
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


## generate templates
template_filenames = [
  tmpl_eruby  = 'bench_eruby.rhtml',
  tmpl_erb    = 'bench_erb.rhtml',
  tmpl_erubis = 'bench_erubis.rhtml',
  tmpl_tenjin  = 'bench_tenjin.rbhtml',
  tmpl_tenjin2 = 'bench_tenjin2.rbhtml',
]
header = File.read("templates/_header.html")
footer = File.read("templates/_footer.html")
template_filenames.uniq.each do |fname|
  begin
    body = File.read("templates/#{fname}")
  rescue
    if fname =~ /tenjin/
      body = File.read("templates/#{tmpl_tenjin}")
    else
      body = File.read("templates/#{tmpl_eruby}")
      body = body.gsub(/list/, '@list') if fname =~ /erubis/
    end
  end
  ## item['key'] ==> item.key
  if mode == 'class'
    body.gsub!(/(\w+)\['(\w+)'\]/, '\1.\2')
  end
  ## escape
  if escape
    case fname
    when /_eruby/
      body.gsub!(/<%= (.*?) %>/, '<%= CGI.escapeHTML((\1).to_s) %>')
    when /_erb/
      body.gsub!(/<%= (.*?) %>/, '<%=h \1 %>')
    when /_erubis/
      body.gsub!(/<%= (.*?) %>/, '<%== \1 %>')
    when /_tenjin/
      body.gsub!(/\#\{(.*?)\}/, '${\1}')
    end
  end
  #
  s = header + body + footer
  File.open(fname, 'w') { |f| f.write(s) }
end



## change benchmark library to use $stderr instead of $stdout
require 'benchmark'
module Benchmark
  class Report
    def print(*args)
      $stderr.print(*args)
    end
  end
  module_function
  def print(*args)
    $stderr.print(*args)
  end
end


## open /dev/null
$stdout = File.open('/dev/null', 'w')
at_exit do
  $stdout.close()
end


##
def delete_caches()
  Dir.glob('*.cache').each { |fname| File.unlink(fname) }
end


## do benchmark
if options['p']
  ntimes = 1
end
output = nil
Benchmark.bm(20) do |job|

  for target in targets
    delete_caches()
    GC.start()
    case target

    when 'eruby'
      job.report(target) do
        ntimes.times do
          ERuby.import(tmpl_eruby)
        end
      end if ERuby

    when 'eruby-cache'
      job.report(target) do
        ntimes.times do
          rbcode = read_and_convert(tmpl_eruby) do |fname|
            ERuby::Compiler.new.compile_string(File.read(fname))
          end
          eval rbcode, bindobj
        end
      end if ERuby

    when 'eruby-convert'
      s = File.read(tmpl_eruby)
      job.report(target) do
        ntimes.times do
          compiler = ERuby::Compiler.new
          output = compiler.compile_string(s)
        end
      end if ERuby

    when 'erb'
      job.report(target) do
        ntimes.times do
          erb = ERB.new(File.read(tmpl_erb))
          output = erb.result(bindobj)
          print output
        end
      end if ERB

    when 'erb-cache'
      job.report(target) do
        ntimes.times do
          rbcode = read_and_convert(tmpl_erb) do |fname|
            ERB.new(File.read(fname)).src
          end
          output = eval rbcode, bindobj
          print output
        end
      end if ERB

    when 'erb-reuse'
      job.report(target) do
        erb = ERB.new(File.read(tmpl_erb))
        ntimes.times do
          output = erb.result(bindobj)
          print output
        end
      end if ERB

    when 'erb-defmethod'
      job.report(target) do
        erb = ERB.new(File.read(tmpl_erb))
        class Dummy; end
        erb.def_method(Dummy, 'render(list)')
        dummy = Dummy.new
        ntimes.times do
          output = dummy.render(context[:list])
          print output
        end
      end if ERB

    when 'erb-convert'
      s = File.read(tmpl_erb)
      job.report(target) do
        ntimes.times do
          erb = ERB.new(s)
          output = erb.src
        end
      end if ERB

    when 'erubis'
      job.report(target) do
        ntimes.times do
          eruby = Erubis::Eruby.new(File.read(tmpl_erubis))
          #output = eruby.result(bindobj)
          output = eruby.evaluate(context)
          print output
        end
      end if Erubis

    when 'erubis-cache'
      job.report(target) do
        ntimes.times do
          erubis = Erubis::Eruby.load_file(tmpl_erubis)
          #output = erubis.result(bindobj)
          output = erubis.evaluate(context)
          print output
        end
      end if Erubis

    when 'erubis-reuse'
      job.report(target) do
        erubis = Erubis::Eruby.new(File.read(tmpl_erubis))
        ntimes.times do
          #output = erubis.result(bindobj)
          output = erubis.evaluate(context)
          print output
        end
      end if Erubis

    when 'erubis-convert'
      s = File.read(tmpl_erubis)
      job.report(target) do
        ntimes.times do
          erubis = Erubis::Eruby.new()
          output = erubis.convert(s)
        end
      end if Erubis

    when 'tenjin-tmpl'
      job.report(target) do
        ntimes.times do
          template = Tenjin::Template.new(tmpl_tenjin)
          output = template.render(context)
          print output
        end
      end if Tenjin

    when 'tenjin-tmpl-reuse'
      job.report(target) do
        template = Tenjin::Template.new(tmpl_tenjin)
        ntimes.times do
          output = template.render(context)
          print output
        end
      end if Tenjin

    when 'tenjin'
      job.report(target) do
        ntimes.times do
          engine = Tenjin::Engine.new(:cache=>true)
          output = engine.render(tmpl_tenjin, context)
          print output
        end
      end if Tenjin

    when 'tenjin-nocache'
      job.report(target) do
        ntimes.times do
          engine = Tenjin::Engine.new(:cache=>false)
          output = engine.render(tmpl_tenjin, context)
          print output
        end
      end if Tenjin

    when 'tenjin-reuse'
      job.report(target) do
        engine = Tenjin::Engine.new()
        ntimes.times do
          output = engine.render(tmpl_tenjin, context)
          print output
        end
      end if Tenjin

    when 'tenjin-convert'
      s = File.read(tmpl_tenjin)
      job.report(target) do
        ntimes.times do
          tenjin = Tenjin::Template.new(:preamble=>true, :postamble=>true)
          output = tenjin.convert(s)
        end
      end if Erubis

    when 'tenjin-defun'
      job.report(target) do
        template = Tenjin::Template.new(tmpl_tenjin)
        defun = defun_code(template.rbcode)
        ntimes.times do
          context.instance_eval(defun)
          output = context.tmpl_tenjin_view()
          print output
        end
      end if Tenjin

    when 'tenjin-defun-reuse'
      job.report(target) do
        template = Tenjin::Template.new(tmpl_tenjin)
        defun = defun_code(template.rbcode)
        context.instance_eval(defun)
        ntimes.times do
          output = context.tmpl_tenjin_view()
          print output
        end
      end if Tenjin

    ##

    when 'tenjin-arrbuftmpl'
      job.report(target) do
        ntimes.times do
          template = Tenjin::ArrayBufferTemplate.new(tmpl_tenjin2)
          output = template.render(context)
          print output
        end
      end if Tenjin::ArrayBufferTemplate

    when 'tenjin-arrbuftmpl-reuse'
      job.report(target) do
        template = Tenjin::ArrayBufferTemplate.new(tmpl_tenjin2)
        ntimes.times do
          output = template.render(context)
          print output
        end
      end if Tenjin::ArrayBufferTemplate

    when 'tenjin-arrbuf'
      job.report(target) do
        ntimes.times do
          engine = Tenjin::Engine.new(:cache=>true, :templateclass=>Tenjin::ArrayBufferTemplate)
          output = engine.render(tmpl_tenjin2, context)
          print output
        end
      end if Tenjin::ArrayBufferTemplate

    when 'tenjin-arrbuf-nocache'
      job.report(target) do
        ntimes.times do
          engine = Tenjin::Engine.new(:cache=>false, :templateclass=>Tenjin::ArrayBufferTemplate)
          output = engine.render(tmpl_tenjin2, context)
          print output
        end
      end if Tenjin::ArrayBufferTemplate

    when 'tenjin-arrbuf-reuse'
      job.report(target) do
        engine = Tenjin::Engine.new(:templateclass=>Tenjin::ArrayBufferTemplate)
        ntimes.times do
          output = engine.render(tmpl_tenjin2, context)
          print output
        end
      end if Tenjin::ArrayBufferTemplate

    when 'tenjin-arrbuf-convert'
      s = File.read(tmpl_tenjin2)
      job.report(target) do
        ntimes.times do
          tenjin = Tenjin::ArrayBufferTemplate.new(:preamble=>true, :postamble=>true)
          output = tenjin.convert(s)
        end
      end if Erubis

    else
      $stderr.puts("*** %s: invalid target.\n" % target)
      exit(1)
    end

    if options['p']
      File.open('%s.result' % target, 'w') { |f| f.write(output) } unless target =~ /^eruby/ && target !~ /-convert$/
      puts 'created: %s.result' % target
      #next
    end

  end

end
