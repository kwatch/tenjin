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


if __FILE__ == $0
  Oktest.run_all()
end
