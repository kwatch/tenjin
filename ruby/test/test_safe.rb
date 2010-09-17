###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"


class SafeStringTest
  include Oktest::TestCase

  def test_to_s
    spec "return self" do
      sstr = Tenjin::SafeString.new('<>')
      ok_(sstr.to_s).same?(sstr)
      ok_(sstr) == '<>'   # not escaped!
    end
  end

end


class ContextHelperTest
  include Oktest::TestCase
  include Tenjin::ContextHelper
  include Tenjin::HtmlHelper

  def test_safe_str
    spec "convert value into SafeString object" do
      ok_(safe_str('<>')).is_a?(Tenjin::SafeString)
      ok_(safe_str(nil)).is_a?(Tenjin::SafeString)
      ok_(safe_str(123)).is_a?(Tenjin::SafeString)
    end
  end

  def test_safe_str?
    spec "return true if arg is SafeString" do
      sstr = Tenjin::SafeString.new('<>')
      ok_(safe_str?(sstr)) == true
    end
    spec "return false if arg is not SafeString" do
      ok_(safe_str?('<>')) == false
    end
  end

  def test_safe_escape
    sstr = safe_str('<>')
    spec "escape arg if it is not SafeString" do
      ok_(safe_escape('<>')) == '&lt;&gt;'
    end
    spec "don't escape arg if it is SafeString" do
      ok_(safe_escape(sstr)) == '<>'
    end
    spec "return SafeString object regardless arg is SafeString or not" do
      ok_(safe_escape('<>')).is_a?(Tenjin::SafeString)
      ok_(safe_escape(sstr)).is_a?(Tenjin::SafeString)
    end
  end

end


class SafeTemplateTest
  include Oktest::TestCase

  def test_initialize
    t = Tenjin::SafeTemplate.new(nil)
    spec "default escapefunc is 'safe_escape'." do
      ok_(t.escapefunc) == 'safe_escape'
    end
  end

  def test_escape_str
    t = Tenjin::SafeTemplate.new(nil)
    spec "escape '#'" do
      ok_(t.escape_str('<#><`><\\>')) == '<\\#><\\`><\\\\>'
    end
  end

  def test_FUNCTEST_convert_and_render
    input = <<'END'
<p>@v1=${@v1}<p>
<p>@v2=${@v2}<p>
<p>safe_str(@v1)=${safe_str(@v1)}<p>
<p>safe_str(@v2)=${safe_str(@v2)}<p>
END
    script = <<'END'
 _buf << %Q`<p>@v1=#{safe_escape((@v1).to_s)}<p>
<p>@v2=#{safe_escape((@v2).to_s)}<p>
<p>safe_str(@v1)=#{safe_escape((safe_str(@v1)).to_s)}<p>
<p>safe_str(@v2)=#{safe_escape((safe_str(@v2)).to_s)}<p>\n`
END
    output = <<'END'
<p>@v1=&lt;&gt;<p>
<p>@v2=<><p>
<p>safe_str(@v1)=<><p>
<p>safe_str(@v2)=<><p>
END
    t = Tenjin::SafeTemplate.new(nil)
    spec "'\#' should be escaped with backslash." do
      ok_(t.convert('<<#{true}>>')) == ' _buf << %Q`<<\\#{true}>>`; ' + "\n"
    end
    spec "use safe_escape() as escape function." do
      ok_(t.convert(input)) == script
    end
    spec "'${s}' doesn't escape if s is SafeString object." do
      context = {:v1=>'<>', :v2=>Tenjin::SafeString.new('<>')}
      ok_(t.render(context)) == output
    end
  end

end


class SafeEngineTest
  include Oktest::TestCase

  def test_initialize
    spec "use SafeTemplate as default template class." do
      e = Tenjin::SafeEngine.new
      ok_(e.templateclass) == Tenjin::SafeTemplate
    end
  end

  def test_FUNCTEST_render
    input = <<'END'
<?rb for item in @items ?>
<tr>
 <td>#{item}</td>
 <td>${item}</td>
 <td>${safe_str(item)}</td>
</tr>
<?rb end ?>
END
    expected = <<'END'
<tr>
 <td>#{item}</td>
 <td>&lt;&gt;</td>
 <td><></td>
</tr>
<tr>
 <td>#{item}</td>
 <td><></td>
 <td><></td>
</tr>
END
    begin
      fname = 'test_safeengine.rbhtml'
      File.open(fname, 'w') {|f| f.write(input) }
      spec "String is escaped but SafeString is not." do
        engine = Tenjin::SafeEngine.new(:postfix=>'.rbhtml')
        context = {:items=>['<>', Tenjin::SafeString.new('<>')]}
        output = engine.render(fname, context)
        ok_(output) == expected
      end
    ensure
      [fname, fname+'.cache'].each do |f|
        File.unlink(f) if File.exist?(f)
      end
    end
  end

end


if __FILE__ == $0
  Oktest.run_all()
end
