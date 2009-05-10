###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require 'test/unit'
#require 'testutil'
require 'testcase-helper'
require 'assert-text-equal'

require 'tenjin'

class TenjinTemplateTest < Test::Unit::TestCase

  filename = __FILE__.sub(/\.\w+$/, '.yaml')
  #load_yaml_testdata(filename)
  if defined?(RBX_VERSION)
    lang = ['rubinius', 'ruby']
  else
    lang = 'ruby'
  end
  eval load_yaml_testdata(filename, :lang=>lang)

  def _test

    @input     ||= nil
    @source    ||= nil
    @expected  ||= nil
    @exception ||= nil
    @errormsg  ||= nil
    @options   ||= {}
    @filename  ||= nil
    @context   ||= {}
    @testopts  ||= nil
    @disabled  ||= nil

    return if @disabled

    @options.keys.each do |key|
      @options[key.intern] = @options.delete(key)
    end

    @templateclass = Tenjin::Template
    if @testopts
      if @testopts.key?('crchar')
        ch = @testopts['crchar']
        @input.gsub!(ch, "\r") if @input
        @source.gsub!(ch, "\r") if @source
        @expected.gsub!(ch, "\r") if @expected
      end
      if @testopts.key?('spacechar')
        ch = @testopts['spacechar']
        @input.gsub!(ch, " ") if @input
        @source.gsub!(ch, " ") if @source
        @expected.gsub!(ch, " ") if @expected
      end
      if @testopts.key?('templateclass')
        klassname = @testopts['templateclass']
        klass = Object
        klassname.split('::').each { |s| klass = klass.const_get(s) }
        @templateclass = klass
      end
    end
    if @exception
      #@exception = eval @exception if @exception.is_a?(String)
      if @exception.is_a?(String)
        @exception = @exception.split('::').inject(Object) {|klass, s| klass = klass.const_get(s) }
      end
      ex = assert_raise(@exception) do
        template = @templateclass.new(@options)
        template.convert(@input, @filename)
        template.render(@context)
      end
      #assert_equal(@exception, ex.class.name)
      if @errormsg
        errmsg = ex.to_s.sub(/:0x[0-9a-fA-F]+/, ':0x12345')
        if defined?(RBX_VERSION)
          assert_equal(@errormsg, errmsg[0, @errormsg.length-1] + '>')
        else
          assert_equal(@errormsg, errmsg)
        end
      end
      assert_equal(@filename, ex.filename) if @filename
    else
      template = @templateclass.new(@options)
      script = template.convert(@input, @filename)
      assert_text_equal(@source, script)
      if @expected
        output = template.render(@context)
        assert_text_equal(@expected, output)
      end
    end

  end


  def test_filename1
    return if ENV['TEST'] && ENV['TEST'] != 'filename1'
    input = <<'END'
<ul>
<?rb for i in 0...3 ?>
<li>#{i}</li>
<?rb end ?>
</ul>
END
    filename = 'test_filename1.rbhtml'
    begin
      File.open(filename, 'w') { |f| f.write(input) }
      template1 = Tenjin::Template.new(filename)
      template2 = Tenjin::Template.new()
      assert_text_equal(template1.script, template2.convert(input))
      assert_text_equal(template1.render(), template2.render())
    ensure
      File.unlink(filename)
    end
  end


  #def test_import_module1()

  #def test_import_module2()


  self.select_target_test()


end
