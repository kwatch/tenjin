###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"

DONT_INVOKE = true
load File.dirname(File.dirname(File.expand_path(__FILE__))) + '/bin/rbtenjin'


def to_list(value)
  return value.is_a?(Array) ? value : [value]
end


INPUT = <<'END'
<ul>
<?rb for item in ['<a&b>', '["c",'+"'d']"] ?>
  <li>#{item}
      ${item}</li>
<?rb end ?>
</ul>
END

INPUT2 = <<'END'
<ul>
<?rb for item in ['<a&b>', '["c",'+"'d']"] ?>
  <li>#{item}
      ${item}</li>
<?rb end ?>
</ul>
END
INPUT2.gsub!(/\n/, "\r\n")

INPUT3 = <<'END'
<?rb
#title = _context['title']
#items = _context.items
?>
<h1>#{@title}</h1>
<ul>
<?rb for item in @items ?>
  <li>#{item}</li>
<?rb end ?>
</ul>
END

SOURCE = <<'END'
_buf = '';  _buf << %Q`<ul>\n`
for item in ['<a&b>', '["c",'+"'d']"]
 _buf << %Q`  <li>#{item}
      #{escape((item).to_s)}</li>\n`
end
 _buf << %Q`</ul>\n`
_buf.to_s
END

SOURCE2 = <<'END'
_buf = '';  _buf << %Q`<ul>\r\n`
for item in ['<a&b>', '["c",'+"'d']"]
 _buf << %Q`  <li>#{item}\r
      #{escape((item).to_s)}</li>\r\n`
end
 _buf << %Q`</ul>\r\n`
_buf.to_s
END
SOURCE2.gsub!(/\n/, "\r\n")

SOURCE4 = <<'END'
_buf = [];  _buf.push('<ul>
'); for item in ['<a&b>', '["c",'+"'d']"]
 _buf.push('  <li>', (item).to_s, '
      ', escape((item).to_s), '</li>
'); end
 _buf.push('</ul>
'); 
_buf.to_s
END

OUTPUT = <<'END'
<ul>
  <li><a&b>
      &lt;a&amp;b&gt;</li>
  <li>["c",'d']
      [&quot;c&quot;,'d']</li>
</ul>
END

OUTPUT2 = <<'END'
<ul>
  <li><a&b>
      &lt;a&amp;b&gt;</li>
  <li>["c",'d']
      [&quot;c&quot;,'d']</li>
</ul>
END
OUTPUT2.gsub!(/\n/, "\r\n")

OUTPUT3 = <<'END'
<h1>rbtenjin example</h1>
<ul>
  <li>aaa</li>
  <li>bbb</li>
  <li>ccc</li>
</ul>
END

CONTEXT1 = <<'END'
title: rbtenjin example
items:
	- aaa
	- bbb
	- ccc
END

CONTEXT2 = <<'END'
@title = 'rbtenjin example'
@items = ['aaa', 'bbb', 'ccc']
END


class TenjinMainTest
  include Oktest::TestCase

  filename = __FILE__.sub(/\.\w+$/, '.yaml')
  #load_yaml_testdata(filename)
  eval load_yaml_testdata(filename)

  def initialize(*args)
    super
    @name = @input = @options = @filename = @context_file = @exception = @errormsg = @expected = nil
  end

  def _test
    @name = (caller[0] =~ /`(.*?)'/) && $&
    return if ENV['TEST'] && ENV['TEST'] != @name
    #
    @input ||= ''
    @options ||= ''
    #
    if @filename != false
      @filename ||= '.test.rbhtml'
      for fname, s in to_list(@filename).zip(to_list(@input))
        File.open(fname, 'w') { |f| f.write(s) }
      end
    end
    #
    if @options.is_a?(Array)
      argv = @options.dup
    elsif @options.is_a?(String)
      argv = @options.split()
    end
    #argv.insert(0, 'rbtenjin')
    argv.concat(to_list(@filename)) if @filename
    if @context_file
      File.open(@context_file, 'w') { |f| f.write(@context_data) }
    end
    main = Tenjin::Main.new(argv)
    if @exception
      if @exception.is_a?(@exception)
        @exception = Kernel.const_get(@exception)
      end
      ex = ok_(proc { output = main.execute() }).raise?(@exception)
      if @errormsg
        ok_(ex.to_s) == @errormsg
      end
    else
      output = main.execute()
      ok_(output) == @expected
    end
  ensure
    to_list(@filename).each { |fname| File.unlink(fname) } if @filename
    File.unlink(@context_file) if @context_file
  end


  def test_help()  # -h
    @options  = "-h"
    @input    = ""
    @expected = Tenjin::Main.new(['rbtenjin']).usage()
    _test()
    #
    @options  = "--help"
    _test()
  end


  def test_version()  # -v, --version
    @options  = "-v"
    @input    = ""
    @expected = Tenjin::Main.new(['rbtenjin']).version() + "\n"
    _test()
    @options  = "--version"
    _test()
  end


#    def test_help_and_version()  # -hVc
#        @options  = "-hVc"
#        @input    = "<?rb foo() ?>"
#        app = Tenjin::Main.new(['rbtenjin'])
#        @expected = app.version() + "\n" + app.usage('rbtenjin')
#        _test()
#    end


  def test_render()  # (nothing), -a render
    @options  = ""
    @input    = INPUT
    @expected = OUTPUT
    _test()
    @options  = '-a render'
    _test()
  end


  def test_source()  # -s, -a convert
    @options  = "-s"
    @input    = INPUT
    @expected = SOURCE
    _test()
    @options  = "-a convert"
    _test()
  end


  def test_source2()  # -s
    @options  = "-s"
    n1 = "<ul>\n".length
    n2 = "</ul>\n".length
    @input    = INPUT[n1...-n2]
    #buf = SOURCE.to_a()[1...-2]
    buf = SOURCE.split(/\n/).collect{|l| l+"\n"}[1..-3]
    buf[0,0] = "_buf = ''; "
    buf << "_buf.to_s\n"
    @expected = buf.join
    #$stderr.puts "*** debug: @input=#{@input}"
    #$stderr.puts "*** debug: @expected=#{@expected}"
    _test()
    @options = "-a convert"
    _test()
  end


  def test_source3()  # -sb, -baconvert
    @options  = "-sb"
    @input    = INPUT
    n1 = "_buf = ''; ".length
    n2 = "_buf.to_s\n".length
    @expected = SOURCE[n1...-n2]
    _test()
    @options = "-baconvert"
    _test()
  end


  INPUT_FOR_RETRIEVE = <<END
<div>
<?rb if list ?>
  <table>
    <thead>
      <tr>
        <th>#</th><th>item</th>
      </tr>
    </thead>
    </tbody>
    <?rb i = 0 ?>
    <?rb for item in list ?>
\t<?rb i += 1 ?>
      <tr bgcolor="${i % 2 ? "#FFCCCC" : "#CCCCFF"}">
\t<td>\#{i}</td>
\t<td>${item}</td>
      </tr>
    <?rb end ?>
    </tbody>
  </table>
<?rb end ?>
</div>
END


  def test_retrieve()  # -S, -a retrieve
    @input = INPUT_FOR_RETRIEVE
    @expected = <<'END'
_buf = ''; 
if list







    i = 0
    for item in list
	i += 1
                   escape((i % 2 ? "#FFCCCC" : "#CCCCFF").to_s); 

	    escape((item).to_s); 

    end


end

_buf.to_s
END
    @options = '-S'
    _test()
    @options = '-a retrieve'
    _test()
  end


  def test_retrieve2()  # -SU, -SNU
    @input = INPUT_FOR_RETRIEVE
    @expected = <<'END'
_buf = ''; 
if list

    i = 0
    for item in list
	i += 1
                   escape((i % 2 ? "#FFCCCC" : "#CCCCFF").to_s); 

	    escape((item).to_s); 

    end

end

_buf.to_s
END
    @options = '-SU'
    _test()
    #
    @expected = <<'END'
    1:  _buf = ''; 
    2:  if list

   10:      i = 0
   11:      for item in list
   12:  	i += 1
   13:                     escape((i % 2 ? "#FFCCCC" : "#CCCCFF").to_s); 

   15:  	    escape((item).to_s); 

   17:      end

   20:  end

   22:  _buf.to_s
END
    @options = '-SUN'
    _test()
  end


  def test_retrieve3()  # -SC, -SNC
    @input = INPUT_FOR_RETRIEVE
    @expected = <<'END'
_buf = ''; 
if list
    i = 0
    for item in list
	i += 1
                   escape((i % 2 ? "#FFCCCC" : "#CCCCFF").to_s); 
	    escape((item).to_s); 
    end
end
_buf.to_s
END
    @options = '-SC'
    _test()
    #
    @expected = <<'END'
    1:  _buf = ''; 
    2:  if list
   10:      i = 0
   11:      for item in list
   12:  	i += 1
   13:                     escape((i % 2 ? "#FFCCCC" : "#CCCCFF").to_s); 
   15:  	    escape((item).to_s); 
   17:      end
   20:  end
   22:  _buf.to_s
END
    @options = '-SNC'
    _test()
  end


  def test_statements()  # -X, -a statements
    @input = INPUT_FOR_RETRIEVE
    @expected = <<'END'
_buf = ''; 
if list







    i = 0
    for item in list
	i += 1
                   

	    

    end


end

_buf.to_s
END
    @options = '-X'
    _test()
    @options = '-a statements'
    _test()
  end

#  def test_dump()  # -d, -a dump
#  end


#  def test_indent()  # -si2
#    @options  = "-si2"
#    @input    = INPUT
#    @expected = SOURCE.replace('    _buf', '  _buf')
#    _test()
#  end


  def test_quiet()  # -q
    @options  = "-z"
    input = INPUT
    @input    = [input, input, input]
    basename = ".test_quiet%d.rbhtml"
    @filename = (0..3).collect { |i| basename % i }
    @expected = (0..3).collect { |i| "#{basename % i}: Syntax OK\n" }.join
    _test()
    #
    @options  = "-zq"
    @expected = ""
    _test()
    @options = "-qasyntax"
    _test()
  end


  def test_invalid_options()  # -Y, -i, -f, -c, -i foo
    @input    = INPUT
    @expected = ""
    @exception = Tenjin::CommandOptionError
    #
    @options  = "-hY"
    @errormsg = "-Y: unknown option."
    _test()
    #
#    @options  = "-i"
#    @filename = false
#    @errormsg = "-i: indent width required."
#    _test()
    #
    @options  = "-f"
    @filename = false
    #@errormsg = "-f: context data filename required."
    @errormsg = "-f: argument required."
    _test()
    #
    @options  = "-c"
    @filename = false
    #@errormsg = "-c: context data string required."
    @errormsg = "-c: argument required."
    _test()
    #
#    @options  = "-i foo"
#    @errormsg = "-i: integer value required."
#    _test()
  end        #


  def test_newline()
    @input    = INPUT2
    @expected = SOURCE2
    @options  = "-s"
    _test()
    @options  = ""
    @expected = OUTPUT2
    _test()
  end


  def test_datafile_yaml() # -f datafile.yaml
    context_filename = 'test.datafile.yaml'
    @options  = "-f " + context_filename
    @input    = INPUT3
    @expected = OUTPUT3
    @context_file = context_filename
    @context_data = CONTEXT1
    _test()
  end


  def test_datafile_rb() # -f datafile.rb
    context_filename = 'test.datafile.rb'
    @options  = "-f " + context_filename
    @input    = INPUT3
    @expected = OUTPUT3
    @context_file = context_filename
    @context_data = CONTEXT2
    _test()
  end


  def test_datafile_error()  # -f file.txt, not-a-mapping context data
    context_filename = 'test.datafile.txt'
    @options = "-f " + context_filename
    @exception = Tenjin::CommandOptionError
    @errormsg = "-f %s: file not found." % context_filename
    _test()
    #
    @context_file = context_filename
    @context_data = "- foo\n- bar\n -baz"
    @errormsg = "-f %s: unknown file type ('*.yaml' or '*.rb' expected)." % context_filename
    _test()
    #
    context_filename = 'test.datafile.yaml'
    @options = "-f " + context_filename
    @errormsg = "%s: not a mapping (hash)." % context_filename
    @context_file = context_filename
    _test()
  end


  def test_context_yaml()  # -c yamlstr
    @options  = ['-c', '{title: rbtenjin example, items: [aaa, bbb, ccc]}']
    @input    = INPUT3
    @expected = OUTPUT3
    _test()
  end


  def test_context_rb()  # -c python-code
    @options  = ['-c', '@title="rbtenjin example";  @items=["aaa", "bbb", "ccc"]']
    @input    = INPUT3
    @expected = OUTPUT3
    _test()
  end


  def test_untabify()  # -T
    context_filename = 'test.datafile.yaml'
    @options  = "-Tf " + context_filename
    @input    = INPUT3
    @expected = OUTPUT3
    @context_file = context_filename
    @context_data = CONTEXT1
    #@exception = yaml.parser.ScannerError
    if defined?(RBX_VERSION)
      @exception = RbYAML::ScannerError
    else
      @exception = ArgumentError
    end
    _test()
  end


  def test_modules()  # -r libraries
    #@options  = "--escapefunc=CGI.escapeHTML"
    @options  = "--escapefunc=ERB::Util.html_escape"
    @input    = INPUT
    @expected = OUTPUT
    @exception = NameError
    if defined?(RBX_VERSION)
      #@errormsg = "Missing or uninitialized constant: CGI"
      @errormsg = "Missing or uninitialized constant: ERB"
    elsif defined?(YARVCore)
      #@errormsg = "uninitialized constant Tenjin::Context::CGI"
      @errormsg = "uninitialized constant Tenjin::Context::ERB"
    else
      #@errormsg = "uninitialized constant Tenjin::Template::CGI"
      @errormsg = "uninitialized constant Tenjin::Template::ERB"
    end
    _test()
    #
    #@options  = "-r cgi --escapefunc=CGI.escapeHTML"
    @options  = "-r erb --escapefunc=ERB::Util.html_escape"
    @input    = INPUT
    @expected = OUTPUT
    @exception = nil
    @errormsg = nil
    _test()
  end


  def test_modules_err()  # -r hogeratta
    @options = '-r hogeratta'
    @exception = Tenjin::CommandOptionError
    @errormsg = '-r hogeratta: library not found.'
    _test()
  end


  def test_escapefunc()  # --escapefunc=cgi.escape
    @options  = "--escapefunc=CGI.escapeHTML -s"
    @input    = INPUT
    @expected = SOURCE.gsub('escape', 'CGI.escapeHTML')
    _test()
  end


#  def test_tostrfunc()  # --tostrfunc=str
#    @options  = "--tostrfunc=str"
#    @input    = INPUT
#    @expected = SOURCE.replace('to_str', 'str')
#    _test()
#  end


  def test_preamble()  # --preamble --postamble
    @options  = ["--preamble=_buf=[];", "--postamble=_buf.join", "-s"]
    @input    = INPUT
    @expected = SOURCE.sub(/^_buf = ''; /, '_buf=[];').sub(/_buf.to_s/, '_buf.join')
    _test()
  end


  def test_templateclass()  # --templateclass
    @options  = "--templateclass=Tenjin::ArrayBufferTemplate -s"
    @input    = INPUT
    @expected = SOURCE4
    _test()
    @options  = "--templateclass=Tenjin::ArrayBufferTemplate"
    @expected = OUTPUT
    _test()
  end


  def test_template_path()  # --path
    layout = <<'END'
<html>
  <body>
#{@_content}
<?rb import(:footer) ?>
  </body>
</html>
END
    body = <<'END'
<ul>
<?rb for item in %w[A B C] ?>
  <li>${item}</li>
<?rb end ?>
</ul>
END
    footer = <<'END'
<hr />
<a href="mailto:webmaster@localhost">webmaser</a>
END
    expected = <<'END'
<html>
  <body>
<ul>
  <li>A</li>
  <li>B</li>
  <li>C</li>
</ul>

<hr />
<a href="mailto:webmaster@localhost">webmaser</a>
  </body>
</html>
END
    # setup
    begin
      Dir.mkdir("tmpl9") unless test(?d, "tmpl9")
      Dir.mkdir("tmpl9/user") unless test(?d, "tmpl9/user")
      File.write("tmpl9/layout.rbhtml", layout)
      File.write("tmpl9/body.rbhtml", '')
      File.write("tmpl9/footer.rbhtml", '')
      File.write("tmpl9/user/body.rbhtml", body)
      File.write("tmpl9/user/footer.rbhtml", footer)
    # body
      @options  = "--path=.,tmpl9/user,tmpl9 --postfix=.rbhtml --layout=:layout"
      @input    = "<?rb import(:body) ?>"
      @expected = expected
      _test()
    # footer
    ensure
      require 'fileutils'
      FileUtils.rm_rf('tmpl9')
    end
  end


  def test_preprocessor  # -P --preprocess
    @options  = "-P"
    @input = <<'END'
<?RB states = { "CA"=>"California", ?>
<?RB            "NY"=>"New York", ?>
<?RB            "FL"=>"Florida", } ?>
<?rb chk = { @user['state'] => ' checked="checked"' } ?>
<select name="state">
<?RB for code in states.keys.sort ?>
  <option value="#{{code}}"#{chk[#{{code.inspect}}]}>${{states[code]}}</option>
<?RB end ?>
</select>
END
    script = <<'END'
<?rb chk = { @user['state'] => ' checked="checked"' } ?>
<select name="state">
  <option value="CA"#{chk["CA"]}>California</option>
  <option value="FL"#{chk["FL"]}>Florida</option>
  <option value="NY"#{chk["NY"]}>New York</option>
</select>
END
    @expected = script
    _test()
    @options = "-apreprocess"
    _test()
    #
    expected = <<'END'
<select name="state">
  <option value="CA">California</option>
  <option value="FL" checked="checked">Florida</option>
  <option value="NY">New York</option>
</select>
END
    @options = ["-c", "{user: {state: FL}}", "--preprocess"]
    @expected = expected
    _test()
  end


end


if __FILE__ == $0
  Oktest.run_all()
end
