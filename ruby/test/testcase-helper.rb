###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

if defined?(RBX_VERSION)
  require 'kwalify'
  def load_yaml_documents_str(s, &block)
    parser = Kwalify::Yaml::Parser.new()
    parser.parse_documents(s, &block)
  end
else
  require 'yaml'
  def load_yaml_documents_str(s, &block)
    YAML.load_documents(s, &block)
  end
end
require 'test/unit/testcase'


def File.write(filename, content)
  File.open(filename, 'w') { |f| f.write(content) }
end


def _data_convert(data, lang='ruby')
  if data.is_a?(Hash)
    data.keys.each do |k|
      v = data[k]
      if k[-1,1] == '*'
        v.is_a?(Hash) or raise "** assertion error"
        data.delete(k)
        if lang.is_a?(Array)
          v = v[ lang.find{|l| v[l]} ]
        else
          v = v[lang]
        end
        data[k[0..-2]] = v
      elsif v.is_a?(Hash) && v.key?(lang)
        data[k] = v[lang]
      else
        _data_convert(v)
      end
    end
  elsif data.is_a?(Array)
    for v in data
      _data_convert(v)
    end
  end
  return data
end



#class Test::Unit::TestCase   # :nodoc:
module Oktest::ClassMethodHelper


  def select_target_test(target_name=ENV['TEST'])
    if target_name
      self.instance_methods.each do |method|
        private method if method =~ /^test_(.*)/ && $1 != target_name
      end
    end
  end


  def _untabify(str, width=8)         # :nodoc:
    list = str.split(/\t/, -1)
    return list.first if list.length == 1
    last = list.pop
    buf = []
    list.each do |s|
      column = (pos = s.rindex(?\n)) ? s.length - pos - 1 : s.length
      n = width - (column % width)
      buf << s << (" " * n)
    end
    buf << last
    return buf.join
    #sb = []
    #str.scan(/(.*?)\t/m) do |s, |
    #  len = (n = s.rindex(?\n)) ? s.length - n - 1 : s.length
    #  sb << s << (" " * (width - len % width))
    #end
    #str = (sb << $').join if $'
    #return str
  end


  def load_yaml_documents(filename, options={})   # :nodoc:
    str = File.read(filename)
    if filename =~ /\.rb$/
      str =~ /^__END__$/   or raise "*** error: __END__ is not found in '#{filename}'."
      str = $'
    end
    str = _untabify(str) unless options[:tabify] == false
    #
    identkey = options[:identkey] || 'name'
    list = []
    table = {}
    load_yaml_documents_str(str) do |ydoc|
      case ydoc
      when Hash  ;  list << ydoc
      when Array ;  list += ydoc
      else       ;  raise "*** invalid ydoc: #{ydoc.inspect}"
      end
    end
    #
    list.each do |ydoc|
      ident = ydoc[identkey]
      ident         or  raise "*** #{identkey} is not found."
      table[ident]  and raise "*** #{identkey} '#{ident}' is duplicated."
      table[ident] = ydoc
    end
    #
    target = $target || ENV['TEST']
    if target
       table[target] or raise "*** target '#{target}' not found."
       list = [ table[target] ]
    end
    #
    list.each do |ydoc| yield(ydoc) end if block_given?
    #
    return list
  end


  SPECIAL_KEYS = %[exception errormsg]

  def load_yaml_testdata(filename, options={})   # :nodoc:
    identkey   = options[:identkey]   || 'name'
    testmethod = options[:testmethod] || '_test'
    lang       = options[:lang]
    special_keys = options[:special_keys] || SPECIAL_KEYS
    s  = ''
    load_yaml_documents(filename, options) do |ydoc|
      ident = ydoc[identkey]
      s  <<   "def test_#{ident}\n"
      ydoc.each do |key, val|
        if key[-1] == ?*
          key = key[0, key.length-1]
          #k = special_keys.include?(key) ? 'ruby' : lang
          if lang.is_a?(Array)
            val = val[ lang.find{|l| val[l]} ]
          else
            val = val[lang]
          end
        end
        s << "  @#{key} = #{val.inspect}\n"
      end
      s  <<  "  #{testmethod}\n"
      s  <<  "end\n"
      $stderr.puts "*** #{_method_name()}(): eval_str=<<'END'\n#{s}END" if $DEBUG
    end
    #module_eval s   # not eval!
    return s
  end


  def _method_name   # :nodoc:
    return (caller[0] =~ /in `(.*?)'/) && $1
  end


  def load_yaml_testdata_with_each_lang(filename, options={})   # :nodoc:
    identkey   = options[:identkey]   || 'name'
    testmethod = options[:testmethod] || '_test'
    special_keys = options[:special_keys] || SPECIAL_KEYS
    langs = defined?($lang) && $lang ? [ $lang ] : options[:langs]
    langs or raise "*** #{_method_name()}(): option ':langs' is required."

    load_yaml_documents(filename, options) do |ydoc|
      ident = ydoc[identkey]
      langs.each do |lang|
        s  =   "def test_#{ident}_#{lang}\n"
        s  <<  "  @lang = #{lang.inspect}\n"
        ydoc.each do |key, val|
          if key[-1] == ?*
            key = key[0, key.length-1]
            k = special_keys.include?(key) ? 'ruby' : lang
            val = val[k]
          end
          s << "  @#{key} = #{val.inspect}\n"
        end
        s  <<  "  #{testmethod}\n"
        s  <<  "end\n"
        #$stderr.puts "*** #{_method_name()}(): eval_str=<<'END'\n#{s}END" if $DEBUG
        module_eval s   # not eval!
      end
    end
  end


end
