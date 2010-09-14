###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"

#class Symbol
#  def <=>(other)
#    return self.to_s <=> other.to_s
#  end
#end
#
#class Hash
#  def each
#    self.keys.sort.each do |key|
#      val = self[key]
#      yield key, val
#    end
#  end
#end


class TenjinExamplesTest
  include Oktest::TestCase

  DIR = File.expand_path(File.dirname(__FILE__) + '/data/examples')
  CWD = Dir.pwd()


  def before
    Dir.chdir DIR
  end


  def after
    Dir.chdir CWD
  end


  def _test
    dirname = File.dirname(@filename)
    if dirname == '.'
      filename = @filename
    else
      filename = File.basename(@filename)
      Dir.chdir(dirname)
    end
    s = File.read(filename)
    s =~ /\A\$ (.*?)\n/
    command = $1
    expected = $'
    result = `#{command}`
    ok_(result) == expected
  end


  Dir.chdir DIR do
    filenames = []
    filenames += Dir.glob('**/*.result')
    filenames += Dir.glob('**/*.source')
    filenames.each do |filename|
      name = filename.gsub(/[^\w]/, '_')
      s = <<-END
        def test_#{name}
          # $stderr.puts "*** debug: test_#{name}"
          @name = '#{name}'
          @filename = '#{filename}'
          _test()
        end
      END
      eval s
    end
  end


end


if __FILE__ == $0
  Oktest.run_all()
end
