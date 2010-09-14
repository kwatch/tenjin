###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"


class TenjinFaqTest
  include Oktest::TestCase

  DIR = File.expand_path(File.dirname(__FILE__) + '/data/faq')
  CWD = Dir.pwd()


  def before
    Dir.chdir DIR
  end


  def after
    Dir.chdir CWD
  end


  def _test
    @name = (caller()[0] =~ /`(.*?)'/) && $1
    s = File.read(@filename)
    s =~ /\A\$ (.*?)\n/
    command = $1
    expected = $'
    result = `#{command}`
    ok_(result) == expected
  end


  Dir.chdir DIR do
    filenames = []
    filenames += Dir.glob('*.result')
    filenames += Dir.glob('*.source')
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
