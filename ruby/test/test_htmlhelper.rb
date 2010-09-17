###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"


class TenjinHtmlHelperTest
  include Oktest::TestCase

  def test_escape_xml
    ok_(Tenjin::HtmlHelper.escape_xml('<>&"')) == '&lt;&gt;&amp;&quot;'
  end

  def test_escape_html
    ok_(Tenjin::HtmlHelper.escape_html('<>&"')) == '&lt;&gt;&amp;&quot;'
  end

  def test_tagattr
    actual = Tenjin::HtmlHelper.tagattr('size', 20)
    expected = ' size="20"'
    ok_(actual) == expected
    #
    actual = Tenjin::HtmlHelper.tagattr('size', nil)
    expected = ''
    ok_(actual) == expected
    #
    actual = Tenjin::HtmlHelper.tagattr('checked', true, 'checked')
    expected = ' checked="checked"'
    ok_(actual) == expected
    #
    actual = Tenjin::HtmlHelper.tagattr('checked', false, 'checked')
    expected = ''
    ok_(actual) == expected
  end

  def test_checked
    actual = Tenjin::HtmlHelper.checked(1==1)
    expected = ' checked="checked"'
    ok_(actual) == expected
    #
    actual = Tenjin::HtmlHelper.checked(1==0)
    expected = ''
    ok_(actual) == expected
  end

  def test_selected
    actual = Tenjin::HtmlHelper.selected(1==1)
    expected = ' selected="selected"'
    ok_(actual) == expected
    #
    actual = Tenjin::HtmlHelper.selected(1==0)
    expected = ''
    ok_(actual) == expected
  end

  def test_disabled
    actual = Tenjin::HtmlHelper.disabled(1==1)
    expected = ' disabled="disabled"'
    ok_(actual) == expected
    #
    actual = Tenjin::HtmlHelper.disabled(1==0)
    expected = ''
    ok_(actual) == expected
  end

  def test_nl2br
    s = """foo\nbar\nbaz\n"""
    actual = Tenjin::HtmlHelper.nl2br(s)
    expected = "foo<br />\nbar<br />\nbaz<br />\n"
    ok_(actual) == expected
  end

  def test_text2html
    s = """foo\n    bar\nba     z\n"""
    actual = Tenjin::HtmlHelper.text2html(s)
    expected = "foo<br />\n &nbsp; &nbsp;bar<br />\nba &nbsp; &nbsp; z<br />\n"
    ok_(actual) == expected
  end

  def test_Cycle
    cycle = Tenjin::HtmlHelper::Cycle.new('odd', 'even')
    ok_("#{cycle}") == 'odd'
    ok_("#{cycle}") == 'even'
    ok_("#{cycle}") == 'odd'
    ok_("#{cycle}") == 'even'
  end


end


if __FILE__ == $0
  Oktest.run_all()
end
