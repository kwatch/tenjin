###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"


class TenjinTemplateTest
  include Oktest::TestCase

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
      ex = ok_(proc {
                 template = @templateclass.new(@options)
                 template.convert(@input, @filename)
                 template.render(@context)
               }).raise?(@exception)
      #ok_(ex.class.name) == @exception
      if @errormsg
        errmsg = ex.to_s.sub(/:0x[0-9a-fA-F]+/, ':0x12345')
        if defined?(RBX_VERSION)
          ok_(errmsg[0, @errormsg.length-1] + '>') == @errormsg
        else
          ok_(errmsg) == @errormsg
        end
      end
      if @filename
        ok_(ex.filename, @filename)
      end
    else
      template = @templateclass.new(@options)
      script = template.convert(@input, @filename)
      ok_(script) == @source
      if @expected
        output = template.render(@context)
        ok_(output) == @expected
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
      ok_(template2.convert(input)) == template1.script
      ok_(template2.render()) == template1.render()
    ensure
      File.unlink(filename)
    end
  end


  #def test_import_module1()

  #def test_import_module2()

  def test_input
    t = Tenjin::Template.new(:input=>"<p>Hello ${name}</p>")
    ok_(t.script) == ' _buf << %Q`<p>Hello #{escape((name).to_s)}</p>`; ' + "\n"
    ok_(t.filename) == nil
    t = Tenjin::Template.new('example.rbhtml', :input=>"<p>Hello ${name}</p>")
    ok_(t.filename) == 'example.rbhtml'
    ok_(t.script) == ' _buf << %Q`<p>Hello #{escape((name).to_s)}</p>`; ' + "\n"
  end


end


if __FILE__ == $0
  Oktest.run_all()
end
