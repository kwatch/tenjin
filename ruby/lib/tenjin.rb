##
## $Copyright$
##
## Permission is hereby granted, free of charge, to any person obtaining
## a copy of this software and associated documentation files (the
## "Software"), to deal in the Software without restriction, including
## without limitation the rights to use, copy, modify, merge, publish,
## distribute, sublicense, and/or sell copies of the Software, and to
## permit persons to whom the Software is furnished to do so, subject to
## the following conditions:
##
## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
## LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
## OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
## WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##

##
## Tenjin module
##
## $Rev$
## $Release: 0.0.0 $
##

module Tenjin

  RELEASE = ('$Release: 0.0.0 $' =~ /[\d.]+/) && $&


  ##
  ## helper module for Context class
  ##
  module HtmlHelper

    module_function

    XML_ESCAPE_TABLE = { '&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#039;' }

    def escape_xml(s)
      #return s.gsub(/[&<>"]/) { XML_ESCAPE_TABLE[$&] }
      return s.gsub(/[&<>"]/) { |s| XML_ESCAPE_TABLE[s] }
      ##
      #s = s.gsub(/&/, '&amp;')
      #s.gsub!(/</, '&lt;')
      #s.gsub!(/>/, '&gt;')
      #s.gsub!(/"/, '&quot;')
      #return s
      ##
      #return s.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/"/, '&quot;')
    end

    alias escape escape_xml

    ## (experimental) return ' name="value"' if expr is not false nor nil.
    ## if value is nil or false then expr is used as value.
    def tagattr(name, expr, value=nil, escape=true)
      if !expr
        return ''
      elsif escape
        return " #{name}=\"#{escape_xml((value || expr).to_s)}\""
      else
        return " #{name}=\"#{value || expr}\""
      end
    end

    ## return ' checked="checked"' if expr is not false or nil
    def checked(expr)
      return expr ? ' checked="checked"' : ''
    end

    ## return ' selected="selected"' if expr is not false or nil
    def selected(expr)
      return expr ? ' selected="selected"' : ''
    end

    ## return ' disabled="disabled"' if expr is not false or nil
    def disabled(expr)
      return expr ? ' disabled="disabled"' : ''
    end

    ## convert "\n" into "<br />\n"
    def nl2br(text)
      return text.to_s.gsub(/\n/, "<br />\n")
    end

    ## convert "\n" and "  " into "<br />\n" and " &nbsp;"
    def text2html(text)
      return nl2br(escape_xml(text.to_s).gsub(/  /, ' &nbsp;'))
    end

    ## cycle values everytime when #to_s() is called
    ## ex:
    ##    cycle = Cycle.new('odd', 'even')
    ##    "#{cycle}"   #=> 'odd'
    ##    "#{cycle}"   #=> 'even'
    ##    "#{cycle}"   #=> 'odd'
    class Cycle
      attr_reader :values
      def initialize(*values)
        @values = values.freeze
        @count  = values.length
        @index  = -1
      end
      def next
        if (@index += 1) == @count
          @index = 0
        end
        return @values[@index]
      end
      alias :to_s :next
    end

  end


  ##
  ## helper module for BaseContext class
  ##
  module ContextHelper

    attr_accessor :_buf, :_engine, :_layout, :_template

    ## escape value. this method should be overrided in subclass.
    def escape(val)
      return val
    end

    ## include template. 'template_name' can be filename or short name.
    def import(template_name, _append_to_buf=true)
      _buf = self._buf
      output = self._engine.render(template_name, context=self, layout=false)
      _buf << output if _append_to_buf
      return output
    end

    ## add value into _buf. this is equivarent to '#{value}'.
    def echo(value)
      self._buf << value
    end

    ##
    ## start capturing.
    ## returns captured string if block given, else return nil.
    ## if block is not given, calling stop_capture() is required.
    ##
    ## ex. list.rbhtml
    ##   <html><body>
    ##     <h1><?rb start_capture(:title) do ?>Document Title<?rb end ?></h1>
    ##     <?rb start_capture(:content) ?>
    ##     <ul>
    ##      <?rb for item in list do ?>
    ##       <li>${item}</li>
    ##      <?rb end ?>
    ##     </ul>
    ##     <?rb stop_capture() ?>
    ##   </body></html>
    ##
    ## ex. layout.rbhtml
    ##   <?xml version="1.0" ?>
    ##   <html xml:lang="en">
    ##    <head>
    ##     <title>${@title}</title>
    ##    </head>
    ##    <body>
    ##     <h1>${@title}</h1>
    ##     <div id="content">
    ##      <?rb echo(@content) ?>
    ##     </div>
    ##    </body>
    ##   </html>
    ##
    def start_capture(varname=nil)
      @_capture_varname = varname
      @_start_position = self._buf.length
      if block_given?
        yield
        output = stop_capture()
        return output
      else
        return nil
      end
    end

    ##
    ## stop capturing.
    ## returns captured string.
    ## see start_capture()'s document.
    ##
    def stop_capture(store_to_context=true)
      output = self._buf[@_start_position..-1]
      self._buf[@_start_position..-1] = ''
      @_start_position = nil
      if @_capture_varname
        self.instance_variable_set("@#{@_capture_varname}", output) if store_to_context
        @_capture_varname = nil
      end
      return output
    end

    ##
    ## if captured string is found then add it to _buf and return true,
    ## else return false.
    ## this is a helper method for layout template.
    ##
    def captured_as(name)
      str = self.instance_variable_get("@#{name}")
      return false unless str
      @_buf << str
      return true
    end

    ##
    ## ex. _p("item['name']")  =>  #{item['name']}
    ##
    def _p(arg)
      return "<`\##{arg}\#`>"    # decoded into #{...} by preprocessor
    end

    ##
    ## ex. _P("item['name']")  =>  ${item['name']}
    ##
    def _P(arg)
      return "<`$#{arg}$`>"    # decoded into ${...} by preprocessor
    end

    ##
    ## decode <`#...#`> and <`$...$`> into #{...} and ${...}
    ##
    def _decode_params(s)
      require 'cgi'
      return s unless s.is_a?(String)
      s = s.dup
      s.gsub!(/%3C%60%23(.*?)%23%60%3E/im) { "\#\{#{CGI::unescape($1)}\}" }
      s.gsub!(/%3C%60%24(.*?)%24%60%3E/im) { "\$\{#{CGI::unescape($1)}\}" }
      s.gsub!(/&lt;`\#(.*?)\#`&gt;/m) { "\#\{#{CGI::unescapeHTML($1)}\}" }
      s.gsub!(/&lt;`\$(.*?)\$`&gt;/m) { "\$\{#{CGI::unescapeHTML($1)}\}" }
      s.gsub!(/<`\#(.*?)\#`>/m, '#{\1}')
      s.gsub!(/<`\$(.*?)\$`>/m, '${\1}')
      return s
    end

    ##
    ## cache fragment data
    ##
    ## ex.
    ##   datacache = Tenjin::FileBaseStore.new("/var/tmp/myapp/dacache")
    ##   Tenjin::Engine.datacache = datacache
    ##   engine = Tenjin::Engine.new
    ##       # or engine = Tenjin::Engine.new(:datacache=>datacache)
    ##   entries = proc { Entry.find(:all) }
    ##   html = engine.render("index.rbhtml", {:entries => entries})
    ##
    ## index.rbhtml:
    ##   <html>
    ##     <body>
    ##       <?rb cache_with("entries/index", 5*60) do ?>
    ##       <?rb   entries = @entries.call ?>
    ##       <ul>
    ##         <?rb for entry in entries ?>
    ##         <li>${entry.title}</li>
    ##         <?rb end ?>
    ##       </ul>
    ##       <?rb end ?>
    ##     </body>
    ##   </html>
    ##
    def cache_with(cache_key, lifetime=nil)
      datacache = self._engine.datacache  or
        raise ArgumentError.new("datacache object is not set for engine object.")
      data = datacache.get(cache_key, self._template.timestamp)
      if data
        echo data
      else
        pos = self._buf.length
        yield
        data = self._buf[pos..-1]
        datacache.set(cache_key, data, lifetime)
      end
      nil
    end

  end


  ##
  ## base class for Context class
  ##
  class BaseContext
    include Enumerable
    include ContextHelper

    def initialize(vars=nil)
      update(vars) if vars.is_a?(Hash)
    end

    def [](key)
      instance_variable_get("@#{key}")
    end

    def []=(key, val)
      instance_variable_set("@#{key}", val)
    end

    def update(hash)
      hash.each do |key, val|
        self[key] = val
      end
    end

    def key?(key)
      return self.instance_variables.include?("@#{key}")
    end
    if Object.respond_to?('instance_variable_defined?')
      def key?(key)
        return self.instance_variable_defined?("@#{key}")
      end
    end

    alias has_key? key?

    def each()
      instance_variables().each do |name|
        if name != '@_buf' && name != '@_engine'
          val = instance_variable_get(name)
          key = name[1..-1]
          yield([key, val])
        end
      end
    end

  end


  ##
  ## context class for Template
  ##
  class Context < BaseContext
    include HtmlHelper
  end


  ##
  ## template class
  ##
  ## ex. file 'example.rbhtml'
  ##   <html>
  ##    <body>
  ##     <h1>${@title}</h1>
  ##     <ul>
  ##     <?rb i = 0 ?>
  ##     <?rb for item in @items ?>
  ##     <?rb   i += 1 ?>
  ##       <li>#{i} : ${item}</li>
  ##     <?rb end ?>
  ##     </ul>
  ##    </body>
  ##   </html>
  ##
  ## ex. convertion
  ##   require 'tenjin'
  ##   template = Tenjin::Template.new('example.rbhtml')
  ##   print template.script
  ##   ## or
  ##   # template = Tenjin::Template.new()
  ##   # print template.convert_file('example.rbhtml')
  ##   ## or
  ##   # template = Tenjin::Template.new()
  ##   # fname = 'example.rbhtml'
  ##   # print template.convert(File.read(fname), fname)  # filename is optional
  ##
  ## ex. evaluation
  ##   context = {:title=>'Tenjin Example', :items=>['foo', 'bar', 'baz'] }
  ##   output = template.render(context)
  ##   ## or
  ##   # context = Tenjin::Context(:title=>'Tenjin Example', :items=>['foo','bar','baz'])
  ##   # output = template.render(context)
  ##   ## or
  ##   # output = template.render(:title=>'Tenjin Example', :items=>['foo','bar','baz'])
  ##   print output
  ##
  class Template

    ESCAPE_FUNCTION = 'escape'  # or 'Eruby::Helper.escape'

    ##
    ## initializer of Template class.
    ##
    ## options:
    ## :escapefunc ::  function name to escape value (default 'escape')
    ## :preamble   ::  preamble such as "_buf = ''" (default nil)
    ## :postamble  ::  postamble such as "_buf.to_s" (default nil)
    ##
    def initialize(filename=nil, options={})
      if filename.is_a?(Hash)
        options = filename
        filename = nil
      end
      @filename   = filename
      @escapefunc = options[:escapefunc] || ESCAPE_FUNCTION
      @preamble   = options[:preamble]  == true ? "_buf = #{init_buf_expr()}; " : options[:preamble]
      @postamble  = options[:postamble] == true ? "_buf.to_s"   : options[:postamble]
      @input      = options[:input]
      @trace      = options[:trace]
      @args       = nil  # or array of argument names
      if @input
        convert(@input, filename)
      elsif filename
        convert_file(filename)
      end
    end
    attr_accessor :filename, :escapefunc, :initbuf, :newline
    attr_accessor :timestamp, :args
    attr_accessor :script #,:bytecode

    ## convert file into ruby code
    def convert_file(filename)
      return convert(File.read(filename), filename)
    end

    ## convert string into ruby code
    def convert(input, filename=nil)
      @input = input
      @filename = filename
      @proc = nil
      pos = input.index(?\n)
      if pos && input[pos-1] == ?\r
        @newline = "\r\n"
        @newlinestr = '\\r\\n'
      else
        @newline = "\n"
        @newlinestr = '\\n'
      end
      before_convert()
      parse_stmts(input)
      after_convert()
      return @script
    end

    protected

    ## hook method called before convert()
    def before_convert()
      @script = ''
      @script << @preamble if @preamble
    end

    ## hook method called after convert()
    def after_convert()
      @script << @newline unless @script[-1] == ?\n
      @script << @postamble << @newline if @postamble
    end

    def self.compile_stmt_pattern(pi)
      return /<\?#{pi}( |\t|\r?\n)(.*?) ?\?>([ \t]*\r?\n)?/m
    end

    STMT_PATTERN = self.compile_stmt_pattern('rb')

    def stmt_pattern
      STMT_PATTERN
    end

    ## parse statements ('<?rb ... ?>')
    def parse_stmts(input)
      return unless input
      is_bol = true
      prev_rspace = nil
      pos = 0
      input.scan(stmt_pattern()) do |mspace, code, rspace|
        m = Regexp.last_match
        text = input[pos, m.begin(0) - pos]
        pos = m.end(0)
        ## detect spaces at beginning of line
        lspace = nil
        if rspace.nil?
          # nothing
        elsif text.empty?
          lspace = "" if is_bol
        elsif text[-1] == ?\n
          lspace = ""
        else
          rindex = text.rindex(?\n)
          if rindex
            s = text[rindex+1..-1]
            if s =~ /\A[ \t]*\z/
              lspace = s
              text = text[0..rindex]
              #text[rindex+1..-1] = ''
            end
          else
            if is_bol && text =~ /\A[ \t]*\z/
              lspace = text
              text = nil
              #lspace = text.dup
              #text[0..-1] = ''
            end
          end
        end
        is_bol = rspace ? true : false
        ##
        text.insert(0, prev_rspace) if prev_rspace
        parse_exprs(text)
        code.insert(0, mspace) if mspace != ' '
        if lspace
          assert if rspace.nil?
          code.insert(0, lspace)
          code << rspace
          #add_stmt(code)
          prev_rspace = nil
        else
          code << ';' unless code[-1] == ?\n
          #add_stmt(code)
          prev_rspace = rspace
        end
        if code
          code = statement_hook(code)
          add_stmt(code)
        end
      end
      #rest = $' || input
      rest = pos > 0 ? input[pos..-1] : input
      rest.insert(0, prev_rspace) if prev_rspace
      parse_exprs(rest) if rest && !rest.empty?
    end

    def expr_pattern
      #return /([\#$])\{(.*?)\}/
      return /(\$)\{(.*?)\}/m
      #return /\$\{.*?\}/
    end

    ## ex. get_expr_and_escapeflag('$', 'item[:name]') => 'item[:name]', true
    def get_expr_and_escapeflag(matched)
      return matched[2], matched[1] == '$'
    end

    ## parse expressions ('#{...}' and '${...}')
    def parse_exprs(input)
      return if !input or input.empty?
      pos = 0
      start_text_part()
      input.scan(expr_pattern()) do
        m = Regexp.last_match
        text = input[pos, m.begin(0) - pos]
        pos = m.end(0)
        expr, flag_escape = get_expr_and_escapeflag(m)
        #m = Regexp.last_match
        #start = m.begin(0)
        #stop  = m.end(0)
        #text  = input[pos, start - pos]
        #expr  = input[start+2, stop-start-3]
        #pos = stop
        add_text(text)
        add_expr(expr, flag_escape)
      end
      rest = $' || input
      #if !rest || rest.empty?
      #  @script << '`; '
      #elsif rest[-1] == ?\n
      #  rest.chomp!
      #  @script << escape_str(rest) << @newlinestr << '`' << @newline
      #else
      #  @script << escape_str(rest) << '`; '
      #end
      flag_newline = input[-1] == ?\n
      add_text(rest, true)
      stop_text_part()
      @script << (flag_newline ? @newline : '; ')
    end

    ## expand macros and parse '#@ARGS' in a statement.
    def statement_hook(stmt)
      ## macro expantion
      #macro_pattern = /\A\s*(\w+)\((.*?)\);?(\s*)\z/
      #if macro_pattern =~ stmt
      #  name = $1; arg  = $2; rspace = $3
      #  handler = get_macro_handler(name)
      #  ret = handler ? handler.call(arg) + $3 : stmt
      #  return ret
      #end
      ## arguments declaration
      if @args.nil?
        args_pattern = /\A *\#@ARGS([ \t]+(.*?))?(\s*)\z/   #
        if args_pattern =~ stmt
          @args = []
          declares = ''
          rspace = $3
          if $2
            for s in $2.split(/,/)
              arg = s.strip()
              next if s.empty?
              arg =~ /\A[a-zA-Z_]\w*\z/ or raise ArgumentError.new("#{arg}: invalid template argument.")
              @args << arg
              declares << " #{arg} = @#{arg};"
            end
          end
          declares << rspace
          return declares
        end
      end
      ##
      return stmt
    end

    #MACRO_HANDLER_TABLE = {
    #  "echo" => proc { |arg|
    #    " _buf << (#{arg});"
    #  },
    #  "import" => proc { |arg|
    #    " _buf << @_engine.render(#{arg}, self, false);"
    #  },
    #  "start_capture" => proc { |arg|
    #    " _buf_bkup = _buf; _buf = \"\"; _capture_varname = #{arg};"
    #  },
    #  "stop_capture" => proc { |arg|
    #    " self[_capture_varname] = _buf; _buf = _buf_bkup;"
    #  },
    #  "start_placeholder" => proc { |arg|
    #    " if self[#{arg}] then _buf << self[#{arg}] else;"
    #  },
    #  "stop_placeholder" => proc { |arg|
    #    " end;"
    #  },
    #}
    #
    #def get_macro_handler(name)
    #  return MACRO_HANDLER_TABLE[name]
    #end

    ## start text part
    def start_text_part()
      @script << " _buf << %Q`"
    end

    ## stop text part
    def stop_text_part()
      @script << '`'
    end

    ## add text string
    def add_text(text, encode_newline=false)
      return unless text && !text.empty?
      if encode_newline && text[-1] == ?\n
        text.chomp!
        @script << escape_str(text) << @newlinestr
      else
        @script << escape_str(text)
      end
    end

    ## escape '\\' and '`' into '\\\\' and '\`'
    def escape_str(str)
      str.gsub!(/[`\\]/, '\\\\\&')
      str.gsub!(/\r\n/, "\\r\r\n") if @newline == "\r\n"
      return str
    end

    ## add expression code
    def add_expr(code, flag_escape=nil)
      return if !code || code.empty?
      @script << (flag_escape ? "\#{#{@escapefunc}((#{code}).to_s)}" : "\#{#{code}}")
    end

    ## add statement code
    def add_stmt(code)
      @script << code
    end

    private

    ## create proc object
    def _render()   # :nodoc:
      return eval("proc { |_context| self._buf = _buf = #{init_buf_expr()}; #{@script}; _buf.to_s }".untaint, nil, @filename || '(tenjin)')
    end

    public

    def init_buf_expr()  # :nodoc:
      return "''"
    end

    ## evaluate converted ruby code and return it.
    ## argument '_context' should be a Hash object or Context object.
    def render(_context=Context.new)
      _context = Context.new(_context) if _context.is_a?(Hash)
      @proc ||= _render()
      if @trace
        s = ""
        s << "<!-- ***** begin: #{@filename} ***** -->\n"
        s << _context.instance_eval(&@proc)
        s << "<!-- ***** end: #{@filename} ***** -->\n"
        return s
      else
        return _context.instance_eval(&@proc)
      end
    end

  end


  ##
  ## preprocessor class
  ##
  class Preprocessor < Template

    protected

    STMT_PATTERN = compile_stmt_pattern('RB')

    def stmt_pattern
      return STMT_PATTERN
    end

    def expr_pattern
      return /([\#$])\{\{(.*?)\}\}/m
    end

    #--
    #def get_expr_and_escapeflag(matched)
    #  return matched[2], matched[1] == '$'
    #end
    #++

    def escape_str(str)
      str.gsub!(/[\\`\#]/, '\\\\\&')
      str.gsub!(/\r\n/, "\\r\r\n") if @newline == "\r\n"
      return str
    end

    def add_expr(code, flag_escape=nil)
      return if !code || code.empty?
      super("_decode_params((#{code}))", flag_escape)
    end

  end


  ##
  ## (experimental) fast template class which use Array buffer and Array#push()
  ##
  ## ex. ('foo.rb')
  ##   require 'tenjin'
  ##   engine = Tenjin::Engine.new(:templateclass=>Tenjin::ArrayBufferTemplate)
  ##   template = engine.get_template('foo.rbhtml')
  ##   puts template.script
  ##
  ## result:
  ##   $ cat foo.rbhtml
  ##   <ul>
  ##   <?rb for item in items ?>
  ##     <li>#{item}</li>
  ##   <?rb end ?>
  ##   </ul>
  ##   $ ruby foo.rb
  ##    _buf.push('<ul>
  ##   '); for item in items
  ##    _buf.push('  <li>', (item).to_s, '</li>
  ##   '); end
  ##    _buf.push('</ul>
  ##   ');
  ##
  class ArrayBufferTemplate < Template

    protected

    def expr_pattern
      return /([\#$])\{(.*?)\}/
    end

    ## parse expressions ('#{...}' and '${...}')
    def parse_exprs(input)
      return if !input or input.empty?
      pos = 0
      items = []
      input.scan(expr_pattern()) do
        prefix, expr = $1, $2
        m = Regexp.last_match
        text = input[pos, m.begin(0) - pos]
        pos = m.end(0)
        items << quote_str(text) if text && !text.empty?
        items << quote_expr(expr, prefix == '$') if expr && !expr.empty?
      end
      rest = $' || input
      items << quote_str(rest) if rest && !rest.empty?
      @script << " _buf.push(" << items.join(", ") << "); " unless items.empty?
    end

    def quote_str(text)
      text.gsub!(/[\'\\]/, '\\\\\&')
      return "'#{text}'"
    end

    def quote_expr(expr, flag_escape)
      return flag_escape ? "#{@escapefunc}((#{expr}).to_s)" : "(#{expr}).to_s"  # or "(#{expr})"
    end

    #--
    #def get_macro_handler(name)
    #  if name == "start_capture"
    #    return proc { |arg|
    #      " _buf_bkup = _buf; _buf = []; _capture_varname = #{arg};"
    #    }
    #  elsif name == "stop_capture"
    #    return proc { |arg|
    #      " self[_capture_varname] = _buf.join; _buf = _buf_bkup;"
    #    }
    #  else
    #    return super
    #  end
    #end
    #++

    public

    def init_buf_expr()  # :nodoc:
      return "[]"
    end

  end


  ##
  ## template class to use eRuby template file (*.rhtml) instead of
  ## Tenjin template file (*.rbhtml).
  ## requires 'erubis' (http://www.kuwata-lab.com/erubis).
  ##
  ## ex.
  ##   require 'erubis'
  ##   require 'tenjin'
  ##   engine = Tenjin::Engine.new(:templateclass=>Tenjin::ErubisTemplate)
  ##
  class ErubisTemplate < Tenjin::Template

    protected

    def parse_stmts(input)
      eruby = Erubis::Eruby.new(input, :preamble=>false, :postamble=>false)
      @script << eruby.src
    end

  end


  ##
  ## abstract class for template cache
  ##
  class TemplateCache

    def cachename(filepath)
      #: return cache file name which is untainted.
      return "#{filepath}.cache".untaint
    end

    def save(filepath, template)
      raise NotImplementedError.new("#{self.class.name}#save(): not implemented yet.")
    end

    def load(filepath, timestamp)
      raise NotImplementedError.new("#{self.class.name}#load(): not implemented yet.")
    end

  end


  ##
  ## dummy template cache
  ##
  class NullTemplateCache < TemplateCache

    def save(filepath, template)
      ## do nothing.
    end

    def load(filepath, timestamp)
      ## do nothing.
    end

  end


  ##
  ## file base template cache which saves template script into file
  ##
  class FileBaseTemplateCache < TemplateCache

    def save(filepath, template)
      #: save template script and args into cache file.
      cache_filepath = cachename(filepath)
      t = template
      tmppath = "#{cache_filepath}#{rand().to_s[1,8]}"
      s = t.args ? "\#@ARGS #{t.args.join(',')}\n" : ''
      File.open(tmppath, 'wb') {|f| f.write(s); f.write(t.script) }
      #: set cache file's mtime to template timestamp.
      File.utime(t.timestamp, t.timestamp, tmppath)
      File.rename(tmppath, cache_filepath)
    end

    def load(filepath, timestamp)
      #: load template data from cache file.
      cache_filepath = cachename(filepath)
      begin
        #: if timestamp of cache file is different from template file, return nil
        mtime = File.mtime(cache_filepath)
        if mtime != timestamp
          #File.unlink(filepath)
          return nil
        end
        script = File.open(cache_filepath, 'rb') {|f| f.read }
      rescue Errno::ENOENT => ex
        #: if template file is not found, return nil.
        return nil
      end
      #: get template args data from cached data.
      args = script.sub!(/\A\#@ARGS (.*)\r?\n/, '') ? $1.split(/,/) : []
      #: return script and template args.
      return [script, args]
    end

  end


  ##
  ## abstract class for data cache (= html fragment cache)
  ##
  class KeyValueStore

    def get(key, *options)
      raise NotImplementedError.new("#{self.class.name}#get(): not implemented yet.")
    end

    def set(key, value, *options)
      raise NotImplementedError.new("#{self.class.name}#set(): not implemented yet.")
    end

    def del(key, *options)
      raise NotImplementedError.new("#{self.class.name}#del(): not implemented yet.")
    end

    def has?(key, *options)
      raise NotImplementedError.new("#{self.class.name}#has(): not implemented yet.")
    end

    def [](key)
      return get(key)
    end

    def []=(key, value)
      return set(key, value)
    end

  end


  ##
  ## memory base data store
  ##
  class MemoryBaseStore < KeyValueStore

    def initialize(lifetime=604800)
      @values = {}
      @lifetime = lifetime
    end
    attr_accessor :values, :lifetime

    def set(key, value, lifetime=nil)
      ## store key and value with current and expired timestamp
      now = Time.now
      @values[key] = [value, now, now + (lifetime || @lifetime)]
    end

    def get(key, original_timestamp=nil)
      ## if cache data is not found, return nil
      arr = @values[key]
      return nil if arr.nil?
      ## if cache data is older than original data, remove it and return nil
      value, created_at, timestamp = arr
      if original_timestamp && created_at < original_timestamp
        del(key)
        return nil
      end
      ## if cache data is expired then remove it and return nil
      if timestamp < Time.now
        del(key)
        return nil
      end
      ## return cache data
      return value
    end

    def del(key)
      ## remove data
      ## don't raise error even if key doesn't exist
      @values.delete(key)
    end

    def has?(key)
      ## if key exists then return true else return false
      return @values.key?(key)
    end

  end


  ##
  ## file base data store
  ##
  class FileBaseStore < KeyValueStore

    def initialize(root, lifetime=604800)  # = 60*60*24*7
      self.root = root
      self.lifetime = lifetime
    end
    attr_accessor :root, :lifetime

    def root=(path)
      unless File.directory?(path)
        raise ArgumentError.new("#{path}: not found.") unless File.exist?(path)
        raise ArgumentError.new("#{path}: not a directory.")
      end
      path = path.chop if path[-1] == ?/
      @root = path
    end

    def filepath(key)
      #return File.join(@root, key.gsub(/[^-.\w\/]/, '_'))
      return "#{@root}/#{key.gsub(/[^-.\w\/]/, '_')}"
    end

    def set(key, value, lifetime=nil)
      ## create directory for cache
      fpath = filepath(key)
      dir = File.dirname(fpath)
      unless File.exist?(dir)
        require 'fileutils' #unless defined?(FileUtils)
        FileUtils.mkdir_p(dir)
      end
      ## create temporary file and rename it to cache file (in order not to flock)
      tmppath = "#{fpath}#{rand().to_s[1,8]}"
      _write_binary(tmppath, value)
      File.rename(tmppath, fpath)
      ## set mtime (which is regarded as cache expired timestamp)
      timestamp = Time.now + (lifetime || @lifetime)
      File.utime(timestamp, timestamp, fpath)
      ## return value
      return value
    end

    def get(key, original_timestamp=nil)
      ## if cache file is not found, return nil
      fpath = filepath(key)
      #return nil unless File.exist?(fpath)
      stat = _ignore_not_found_error { File.stat(fpath) }
      return nil if stat.nil?
      ## if cache file is older than original data, remove it and return nil
      if original_timestamp && stat.ctime < original_timestamp
        del(key)
        return nil
      end
      ## if cache file is expired then remove it and return nil
      if stat.mtime < Time.now
        del(key)
        return nil
      end
      ## return cache file content
      return _ignore_not_found_error { _read_binary(fpath) }
    end

    def del(key, *options)
      ## delete data file
      ## if data file doesn't exist, don't raise error
      fpath = filepath(key)
      _ignore_not_found_error { File.unlink(fpath) }
      nil
    end

    def has?(key)
      ## if key exists then return true else return false
      return File.exist?(filepath(key))
    end

    private

    if RUBY_PLATFORM =~ /mswin(?!ce)|mingw|cygwin|bccwin/i
      def _read_binary(fpath)
        File.open(fpath, 'rb') {|f| f.read }
      end
    else
      def _read_binary(fpath)
        File.read(fpath)
      end
    end

    def _write_binary(fpath, data)
      File.open(fpath, 'wb') {|f| f.write(data) }
    end

    def _ignore_not_found_error(default=nil)
      begin
        return yield
      rescue Errno::ENOENT => ex
        return default
      end
    end

  end



  ##
  ## engine class for templates
  ##
  ## Engine class supports the followings.
  ## * template caching
  ## * partial template
  ## * layout template
  ## * capturing (experimental)
  ##
  ## ex. file 'ex_list.rbhtml'
  ##   <ul>
  ##   <?rb for item in @items ?>
  ##     <li>#{item}</li>
  ##   <?rb end ?>
  ##   </ul>
  ##
  ## ex. file 'ex_layout.rbhtml'
  ##   <html>
  ##    <body>
  ##     <h1>${@title}</li>
  ##   #{@_content}
  ##   <?rb import 'footer.rbhtml' ?>
  ##    </body>
  ##   </html>
  ##
  ## ex. file 'main.rb'
  ##   require 'tenjin'
  ##   options = {:prefix=>'ex_', :postfix=>'.rbhtml', :layout=>'ex_layout.rbhtml'}
  ##   engine = Tenjin::Engine.new(options)
  ##   context = {:title=>'Tenjin Example', :items=>['foo', 'bar', 'baz']}
  ##   output = engine.render(:list, context)  # or 'ex_list.rbhtml'
  ##   print output
  ##
  class Engine

    ##
    ## initializer of Engine class.
    ##
    ## options:
    ## :prefix  :: prefix string for template name (ex. 'template/')
    ## :postfix :: postfix string for template name (ex. '.rbhtml')
    ## :layout  :: layout template name (default nil)
    ## :path    :: array of directory name (default nil)
    ## :cache   :: save converted ruby code into file or not (default true)
    ## :path    :: list of directory (default nil)
    ## :preprocess :: flag to activate preprocessing (default nil)
    ## :templateclass :: template class object (default Tenjin::Template)
    ##
    def initialize(options={})
      @prefix  = options[:prefix]  || ''
      @postfix = options[:postfix] || ''
      @layout  = options[:layout]
      @path    = options[:path]
      @cache   = _template_cache(options[:cache])
      @preprocess = options.fetch(:preprocess, nil)
      @datacache = options[:datacache] || @@datacache
      @templateclass = options.fetch(:templateclass, Template)
      @init_opts_for_template = options
      @_templates = {}   # template_name => [template_obj, filepath]
    end
    attr_accessor :datacache, :cache

    def _template_cache(cache)  #:nodoc:
      #: if cache is nil or true then return @@template_cache
      return @@template_cache if cache.nil? || cache == true
      #: if cache is false tehn return NullemplateCache object
      return NullTemplateCache.new if cache == false
      #: if cache is an instnce of TemplateClass then return it
      return cache if cache.is_a?(TemplateCache)
      #: if else then raises error
      raise ArgumentError.new(":cache is expected true, false, or TemplateCache object")
    end
    private :_template_cache

    @@template_cache = FileBaseTemplateCache.new()
    def self.template_cache;     @@template_cache;     end
    def self.template_cache=(x); @@template_cache = x; end

    @@datacache = MemoryBaseStore.new()
    def self.datacache;     @@datacache;     end
    def self.datacache=(x); @@datacache = x; end

    ## convert short name into filename (ex. ':list' => 'template/list.rb.html')
    def to_filename(template_name)
      #: if template_name is a Symbol, add prefix and postfix to it.
      #: if template_name is not a Symbol, just return it.
      name = template_name
      return name.is_a?(Symbol) ? "#{@prefix}#{name}#{@postfix}" : name
    end

    ## find template file path
    def find_template_path(filename)
      #: if @path is provided then search template file from it.
      if @path
        for dir in @path
          filepath = File.join(dir, filename)
          return filepath if test(?f, filepath.untaint)
        end
      #: if @path is not provided then just return filename if file exists.
      else
        return filename if test(?f, filename.dup.untaint)  # dup is required for frozen string
      end
      #: return nil if template file is not found.
      return nil
    end

    ## return file path and mtime of template file
    def find_template_file(template_name)
      #: accept template_name such as :index
      filename = to_filename(template_name)
      #: if template file is not found then raises Errno::ENOENT.
      filepath = find_template_path(filename)  or
        raise Errno::ENOENT.new("#{filename} (path=#{@path.inspect})")
      #: return file path and mtime of template file.
      return filepath, File.mtime(filepath)
      #/: return full path and mtime of template file.
      #fullpath = File.expand_path(filepath)
      #return fullpath, File.mtime(filepath)
    end

    ## read template file and preprocess it
    def read_template_file(filename, _context=nil)
      #: if preprocessing is not enabled, just read template file and return it.
      return File.read(filename) if !@preprocess
      #: if preprocessing is enabled, read template file and preprocess it.
      _context ||= {}
      _context = hook_context(_context) if _context.is_a?(Hash) || _context._engine.nil?
      _buf = _context._buf
      _context._buf = ""
      begin
        return Preprocessor.new(filename).render(_context)
      ensure
        _context._buf = _buf
      end
    end

    ## register template object
    def register_template(template_name, template)
      #: register template object without file path.
      @_templates[template_name] = [template, nil]
    end

    ## create template object from file
    def create_template(filepath, timestamp=nil, _context=nil)
      #: if filepath is specified then create template from it.
      #: if filepath is not specified then just create empty template object.
      template = @templateclass.new(nil, @init_opts_for_template)
      if filepath
        _context ||= hook_context(Context.new)
        input = read_template_file(filepath, _context)
        template.convert(input, filepath)
        #: if filepath is specified but not timestamp then use file's mtime as timestamp
        template.timestamp = timestamp || File.mtime(filepath)
      else
        #: set timestamp of template object.
        template.timestamp = timestamp
      end
      #: return template object
      return template
    end

    def _set_template_attrs(template, filepath, script, args)
      #: set template attributes.
      template.filename = filepath
      template.script   = script
      template.args     = args
    end
    private :_set_template_attrs

    ## get template object
    def get_template(template_name, _context=nil)
      #: if template object is in memory cache...
      template, filepath = @_templates[template_name]
      if template
        if filepath
          #: ... and it's timestamp is same as file, return it.
          template.timestamp != nil  or raise "** assertion afiled"
          return template if template.timestamp == File.mtime(filepath)
          @_templates[template_name] = nil
        else
          #: ... but it doesn't have file path, don't check timestamp.
          return template unless filepath
        end
      end
      #: if template object is not found in memory cache, load from file cache.
      filepath, timestamp = find_template_file(template_name)
      template = @cache.load(filepath, timestamp)
      #: if file cache data is a pair of script and args, create template object from them.
      if template.is_a?(Array)
        script, args = template
        template = create_template(nil, timestamp, _context)
        _set_template_attrs(template, filepath, script, args)
      end
      #: if template is not found in file cache, create it and save to file cache.
      if ! template
        template = create_template(filepath, timestamp, _context)
        @cache.save(filepath, template)
      end
      #: save template object into memory cache with file path.
      @_templates[template_name] = [template, filepath]
      #: return template object.
      return template
    end

    ## get template object and evaluate it with context object.
    ## if argument 'layout' is true then default layout file (specified at
    ## initializer) is used as layout template, else if false then no layout
    ## template is used.
    ## if argument 'layout' is string, it is regarded as layout template name.
    def render(template_name, context=Context.new, layout=true)
      # if context is a Hash object, convert it into Context object.
      context = hook_context(context)
      while true
        template = get_template(template_name, context)  # context is passed only for preprocessor
        _tmpl = context._template
        context._template = template
        _buf = context._buf
        output = template.render(context)
        context._template = _tmpl
        context._buf = _buf
        unless context._layout.nil?
          layout = context._layout
          context._layout = nil
        end
        layout = @layout if layout == true or layout.nil?
        break unless layout
        template_name = layout
        layout = false
        context.instance_variable_set('@_content', output)
      end
      return output
    end

    def hook_context(context)
      if !context
        context = Context.new
      elsif context.is_a?(Hash)
        context = Context.new(context)
      end
      context._engine = self
      context._layout = nil
      return context
    end

  end


end
