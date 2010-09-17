###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"
require 'fileutils'

if defined?(RBX_VERSION)
  require 'kwalify'
  def load_yaml_str(s)
    return Kwalify::Yaml.load(s)
  end
else
  require 'yaml'
  def load_yaml_str(s)
    return YAML.load(s)
  end
end



class TenjinEngineTest
  include Oktest::TestCase

  s = File.read(__FILE__.sub(/\.\w+$/, '.yaml'))
  s.gsub!(/^\t/, ' ' * 8)
  ydoc = load_yaml_str(s)
  _data_convert(ydoc, 'ruby')
  TESTDATA = {}
  ydoc.each { |e| TESTDATA[e['name']] = e }
  TESTDATA['basic']['templates'].each do |d|
    d['filename'].sub!(/\.xxhtml$/, '.rbhtml')
  end

  def _setup
    TESTDATA['basic']['templates'].each do |hash|
      File.write(hash['filename'], hash['content'])
    end
  end

  def _teardown
    TESTDATA['basic']['templates'].each do |hash|
      filenames = [hash['filename'], hash['filename']+'.cache']
      filenames.each do |fname|
        File.unlink(fname) if test(?f, fname)
      end
    end
  end

  def _read_file(fname)
    File.open(fname, 'rb') {|f| f.read() }
  end

  def _remove_files(*filenames)
    for filename in filenames.flatten
      for fname in Dir.glob("#{filename}*")
        File.unlink(fname)
      end
    end
  end

  def _template_class
    Tenjin::Template
  end

  def _test_basic
    ## setup
    _setup()

    ## body
    begin
      testname = (caller[0] =~ /`(.*)'/) && $1
      list = testname.split('_')
      action   = list[2]                # 'list', 'show', 'create', or 'edit'
      shortp   = list[3] != 'filename'  # template short name or filename
      layoutp  = list[4] != 'nolayout'  # use layout or not
      layout   = layoutp ? 'user_layout.rbhtml' : nil
      engine   = Tenjin::Engine.new(:prefix=>'user_', :postfix=>'.rbhtml', :layout=>layout, :templateclass=>_template_class())
      context  = TESTDATA['basic']['contexts'][action]
      key      = 'user_' + action + (layout ? '_withlayout' : '_nolayout')
      expected = TESTDATA['basic']['expected'].find{|h| h['name'] == key}['content']
      filename = 'user_%s.rbhtml' % action
      tplname  = shortp ? action.intern : filename
      output   = engine.render(tplname, context, layoutp)
      ok_(output) == expected

    ## teardown
    ensure
      _teardown
    end
  end


  # fileame, nolayout

  def test_basic_list_filename_nolayout
    _test_basic
  end

  def test_basic_show_filename_nolayout
    _test_basic
  end

  def test_basic_create_filename_nolayout
    _test_basic
  end

  def test_basic_edit_filename_nolayout
    _test_basic
  end


  # shortname, nolayout

  def test_basic_list_shortname_nolayout
    _test_basic
  end

  def test_basic_show_shortname_nolayout
    _test_basic
  end

  def test_basic_create_shortname_nolayout
    _test_basic
  end

  def test_basic_edit_shortname_nolayout
    _test_basic
  end


  # filename, withlayout

  def test_basic_list_filename_withlayout
    _test_basic
  end

  def test_basic_show_filename_withlayout
    _test_basic
  end

  def test_basic_create_filename_withlayout
    _test_basic
  end

  def test_basic_edit_filename_withlayout
    _test_basic
  end


  # shortname, withlayout

  def test_basic_list_shortname_withlayout
    _test_basic
  end

  def test_basic_show_shortname_withlayout
    _test_basic
  end

  def test_basic_create_shortname_withlayout
    _test_basic
  end

  def test_basic_edit_shortname_withlayout
    _test_basic
  end


  ## ----------------------------------------

  def test_capture_and_echo
    hash = TESTDATA['test_capture_and_echo']
    layout   = hash['layout']
    content  = hash['content']
    expected = hash['expected']
    layout_filename = 'user_layout.rbhtml'
    content_filename = 'user_content.rbhtml'
    begin
      File.write(layout_filename, layout)
      File.write(content_filename, content)
      engine = Tenjin::Engine.new(:prefix=>'user_', :postfix=>'.rbhtml', :layout=>:layout, :templateclass=>_template_class())
      context = { :items => %w[AAA BBB CCC] }
      result = engine.render(:content, context)
      ok_(result) == expected
    ensure
      [layout_filename, layout_filename + '.cache',
       content_filename, content_filename + '.cache'].each do |filename|
        File.unlink(filename) if test(?f, filename)
      end
    end
  end


  def test_captured_as
    hash = TESTDATA['test_captured_as']
    files = [
      ['baselayout.rbhtml', hash['baselayout']],
      ['customlayout.rbhtml', hash['customlayout']],
      ['content.rbhtml', hash['content']],
    ]
    context = hash['context']
    expected = hash['expected']
    begin
      for filename, content in files
        File.write(filename, content)
      end
      engine = Tenjin::Engine.new(:postfix=>'.rbhtml', :templateclass=>_template_class())
      result = engine.render(:content, context)
      ok_(result) == expected
    ensure
      for filename, content in files
        for fname in Dir.glob("#{filename}*")
          File.unlink(fname) if test(?f, fname)
        end
      end
    end
  end


  def test_local_layout
    hash = TESTDATA['test_local_layout']
    context = hash['context']
    names = ['layout_html', 'layout_xhtml', 'content_html']
    fname = lambda { |base| 'local_%s.rbhtml' % base }
    begin
      names.each do |name|
        File.write(fname.call(name), hash[name])
      end
      engine = Tenjin::Engine.new(:prefix=>'local_', :postfix=>'.rbhtml', :layout=>:layout_html, :templateclass=>_template_class())
      ##
      content_html = hash['content_html']
      File.write(fname.call('content_html'), content_html)
      actual = engine.render(:content_html, context)
      ok_(actual) == hash['expected_html']
      ##
      sleep(1)
      content_html = hash['content_html'] + "<?rb @_layout = :layout_xhtml ?>\n"
      File.write(fname.call('content_html'), content_html)
      actual = engine.render(:content_html, context)
      ok_(actual) == hash['expected_xhtml']
      ##
      sleep(1)
      content_html = hash['content_html'] + "<?rb @_layout = false ?>\n"
      File.write(fname.call('content_html'), content_html)
      actual = engine.render(:content_html, context)
      ok_(actual) == hash['expected_nolayout']
    ensure
      names.collect {|name| fname.call(name)}.each do |filename|
        File.unlink(filename) if test(?f, filename)
        filename += '.cache'
        File.unlink(filename) if test(?f, filename)
      end
    end
  end


  def test_cachefile
    data = TESTDATA['test_cachefile']
    filenames = {
      'layout'=> 'layout.rbhtml',
      'page'  => 'account_create.rbhtml',
      'form'  => 'account_form.rbhtml',
    }
    expected = data['expected']
    context = { 'params'=> { } }
    begin
      for key, filename in filenames
        File.write(filename, data[key])
      end
      args = { :prefix=>'account_', :postfix=>'.rbhtml',
               :layout=>'layout.rbhtml', :templateclass=>_template_class() }
      ## no caching
      args[:cache] = false
      engine = Tenjin::Engine.new(args)
      output = engine.render(:create, context)
      ok_(output) == expected
      not_ok_('account_create.rbhtml.cache').exist?
      #not_ok_('account_create.rbhtml.pstore').exist?
      not_ok_('account_form.rbhtml.cache').exist?
      not_ok_('account_form.rbhtml.pstore').exist?
      ## ruby code caching
      args[:cache] = true
      engine = Tenjin::Engine.new(args)
      output = engine.render(:create, context)
      ok_('account_create.rbhtml.cache').file?
      #not_ok_('account_create.rbhtml.cache').exist?
      ok_('account_form.rbhtml.cache').file?
      #not_ok_('account_form.rbhtml.pstore').exist?
      File.unlink('account_create.rbhtml.cache')
      File.unlink('account_form.rbhtml.cache')
      ## pstore caching
      #args[:cache] = true
      #engine = Tenjin::Engine(args)
      #output = engine.render(:create, context)
      #not_ok_('account_create.rbhtml.cache').file?
      #not_ok_('account_create.rbhtml.pstore').file?
      #not_ok_('account_form.rbhtml.cache').file?
      #not_ok_('account_form.rbhtml.pstore').file?
    ensure
      for key, filename in filenames
        for fname in [filename, filename+'.cache', filename+'.pstore']
          test(?f, fname) and File.unlink(fname)
        end
      end
    end

  end



  def test_template_args
    data = TESTDATA['test_template_args']
    content = data['content']
    expected = data['expected']
    errormsg = data['errormsg']
    exception = eval(data['exception'])
    context = data['context']
    for basename in %w[content]
      File.write("#{basename}.rbhtml", data[basename])
    end
    # when no cache file
    args1 = nil;
    ex = ok_(proc {
               not_ok_('content.rbhtml.cache').file?
               engine = Tenjin::Engine.new(:cache=>true)
               args1 = engine.get_template('content.rbhtml').args
               not_ok_(args1) == nil
               output = engine.render('content.rbhtml', context)
             }).raise?(exception)
    msg = ex.to_s.sub(/:0x[0-9a-fA-F]\w+/, ':0x12345')
    msg = msg[0, errormsg.length-1]+'>' if defined?(RBX_VERSION)
    ok_(msg) == errormsg
    # when cache file exist
    ex = ok_(proc {
               #File.unlink('content.rbhtml');
               ok_('content.rbhtml.cache').file?
               engine = Tenjin::Engine.new(:cache=>true)
               args2 = engine.get_template('content.rbhtml').args
               not_ok_(args2) == nil
               ok_(args2) == args1
               output = engine.render('content.rbhtml', context)
             }).raise?(NameError)
    #ok_(ex.to_s.sub(/:0x\w+>/, '>')) == errormsg
    msg = ex.to_s.sub(/:0x[0-9a-fA-F]\w+/, ':0x12345')
    msg = msg[0, errormsg.length-1]+'>' if defined?(RBX_VERSION)
    ok_(msg) == errormsg
  ensure
    _remove_files(['content'])
  end


  def test_cached_contents
    return if ENV['TEST'] && ENV['TEST'] != 'template_args'
    data = TESTDATA['test_cached_contents']
    filename = 'input.pyhtml'
    cachename = filename+'.cache'
    _testproc = proc do |cacheflag, n|
      script = data["script#{n}"]
      cache   = data["cache#{n}"]
      args    = data["args#{n}"]
      cachename = filename+'.cache'
      engine = Tenjin::Engine.new(:cache=>cacheflag)
      t = engine.get_template(filename)
      ok_(t.args) == args
      ok_(t.script) == script
      cache_actual = File.read(engine.cachename(filename))
      ok_(cache_actual) == cache
    end
    #
    ## args=[x,y,z], cache=1
    for f in Dir.glob(filename+'*') do File.unlink(f) end
    File.write(filename, data["input1"])
    not_ok_(cachename).file?
    _testproc.call(cacheflag=true, n=1)
    ok_(cachename).file?
    _testproc.call(cacheflag=true, n=1)
    ## args=[], cache=1
    sleep(1)
    File.write(filename, data["input2"])
    #ok_(cachename).file?
    _testproc.call(cacheflag=true, n=2)
    #ok_(cachename).file?
    _testproc.call(cacheflag=true, n=2)
  ensure
    _remove_files(['input.pyhtml'])
  end


  def _test_template_path(arg1, arg2, arg3)
    data = TESTDATA['test_template_path']
    basedir = 'test_templates'
    keys = [arg1, arg2, arg3]
    begin
      for dir in [basedir, "#{basedir}/common", "#{basedir}/user"]
        Dir.mkdir(dir) unless test(?d, dir)
      end
      d = { 'layout'=>arg1, 'body'=>arg2, 'footer'=>arg3 }
      for key in %w[layout body footer]
        filename = "#{basedir}/common/#{key}.rbhtml"
        File.write(filename, data["common_#{key}"])
        if d[key] == 'user'
          filename = "#{basedir}/user/#{key}.rbhtml"
          File.write(filename, data["user_#{key}"])
        end
      end
      #
      path = ["#{basedir}/user", "#{basedir}/common"]
      engine = Tenjin::Engine.new(:postfix=>'.rbhtml', :path=>path, :layout=>:layout, :templateclass=>_template_class())
      context = { :items=>%w[AAA BBB CCC] }
      output = engine.render(:body, context)
      #
      expected = data["expected_#{keys.join('_')}"]
      ok_(output) == expected
    ensure
      FileUtils.rm_rf(basedir)
    end
  end

  def test_template_path_common_common_common()
    _test_template_path('common', 'common', 'common')
  end
  def test_template_path_user_common_common()
    _test_template_path('user',   'common', 'common')
  end
  def test_template_path_common_user_common()
    _test_template_path('common', 'user',   'common')
  end
  def test_template_path_user_user_common()
    _test_template_path('user',   'user',   'common')
  end
  def test_template_path_common_common_user()
    _test_template_path('common', 'common', 'user')
  end
  def test_template_path_user_common_user()
    _test_template_path('user',   'common', 'user')
  end
  def test_template_path_common_user_user()
    _test_template_path('common', 'user',   'user')
  end
  def test_template_path_user_user_user()
    _test_template_path('user',   'user',   'user')
  end


  def test_preprocessor
    return if ENV['TEST'] && ENV['TEST'] != 'preprocessor'
    data = TESTDATA['test_preprocessor']
    form = data['form']
    create = data['create']
    update = data['update']
    layout = data['layout']
    context = data['context']
    #
    basenames = %w[form create update layout]
    filenames = []
    basenames.each do |name|
      filenames << (filename = "prep_#{name}.rbhtml")
      File.write(filename, data[name])
    end
    engine = Tenjin::Engine.new(:prefix=>'prep_', :postfix=>'.rbhtml', :layout=>:layout, :preprocess=>true)
    #
    context = { :title=>'Create', :action=>'create', :params=>{'state'=>:NY} }
    actual = engine.render(:create, context)  # 1st
    ok_(actual) == data['expected1']
    context[:params] = {'state'=>:xx}
    actual = engine.render(:create, context)  # 2nd
    #ok_(actual) == data['expected1']
    ok_(actual) == data['expected1'].sub(/ checked="checked"/, '')
    #
    context = { :title=>'Update', :action=>'update', :params=>{'state'=>:NY} }
    actual = engine.render(:update, context)  # 1st
    ok_(actual) == data['expected2']
    context[:params] = {'state'=>:xx}
    actual = engine.render(:update, context)  # 2nd
    ok_(actual) == data['expected2']  # not changed!
    #ok_(actual) == data['expected2'].sub(/ checked="checked"/, '')
  ensure
    _remove_files(Dir.glob('prep_*'))
  end


  def test_include_with_preprocess
    data = TESTDATA['test_include_with_preprocess']
    index_rbhtml = data['index_html']
    show_rbhtml  = data['show_html']
    expected     = data['expected']
    testopts     = data['testopts']
    #
    File.write("index.rbhtml", index_rbhtml)
    File.write("show.rbhtml", show_rbhtml)
    #
    engine = Tenjin::Engine.new(:cache=>false, :preprocess=>false)
    actual = engine.render("index.rbhtml")
    ok_(actual) == expected
    #
    engine = Tenjin::Engine.new(:cache=>false, :preprocess=>true)
    actual = engine.render("index.rbhtml")
    ok_(actual) == expected
  ensure
    %w[index.rbhtml show.rbhtml].each {|x| File.unlink(x) if File.exist?(x) }
  end


  def test_fragmentcache
    input = <<'END'
<html>
  <body>
    <?rb cache_with("entries/index", 5*60) do ?>
    <?rb   entries = @entries.call ?>
    <ul>
      <?rb for entry in entries ?>
      <li>${entry}</li>
      <?rb end ?>
    </ul>
    <?rb end ?>
  </body>
</html>
END
    expected_output = <<'END'
<html>
  <body>
    <ul>
      <li>Haruhi</li>
      <li>Mikuru</li>
      <li>Yuki</li>
      <li>Kyon</li>
      <li>Itsuki</li>
    </ul>
  </body>
</html>
END
    expected_cache = <<'END'
    <ul>
      <li>Haruhi</li>
      <li>Mikuru</li>
      <li>Yuki</li>
      <li>Kyon</li>
      <li>Itsuki</li>
    </ul>
END
    expected_output1 = expected_output.gsub(/^.*(Kyon|Itsuki).*\n/, '')
    expected_cache1  = expected_cache .gsub(/^.*(Kyon|Itsuki).*\n/, '')
    expected_output2 = expected_output.gsub(/^.*(Itsuki).*\n/, '')
    expected_cache2  = expected_cache .gsub(/^.*(Itsuki).*\n/, '')
    expected_output3 = expected_output
    expected_cache3  = expected_cache
    #
    begin
      fname = "fragtest.rbhtml"
      File.open(fname, 'wb') {|f| f.write(input) }
      cachedir = ".test.fragcache"
      Dir.mkdir(cachedir)
      fragcache_fpath = "#{cachedir}/entries/index"
      kv_store = Tenjin::FileBaseStore.new(cachedir)
      Tenjin::Engine.data_cache = kv_store
      engine = Tenjin::Engine.new
          # or engine = Tenjin::Engine.new(:data_cache=>kv_store)
      spec "if called first time then calls block and save output to cache store" do
        called = false
        entries = proc { called = true; ['Haruhi', 'Mikuru', 'Yuki'] }
        html = engine.render(fname, {:entries => entries})
        ok_(called) == true
        ok_(fragcache_fpath).exist?
        ok_(html) == expected_output1
        ok_(_read_file(fragcache_fpath)) == expected_cache1
      end
      spec "if called second time then don't call block and reuse cached data" do
        called = false
        entries = proc { called = true; ['Haruhi', 'Mikuru', 'Yuki'] }
        html = engine.render(fname, {:entries => entries})
        ok_(called) == false
        ok_(html) == expected_output1
      end
      spec "if called after cache is expired then block is called again" do
        called = false
        entries = proc { called = true; ['Haruhi', 'Mikuru', 'Yuki', 'Kyon'] }
        ## expire cache
        atime = File.atime(fragcache_fpath)
        mtime = File.mtime(fragcache_fpath)
        File.utime(atime, mtime-5*60, fragcache_fpath)
        mtime = File.mtime(fragcache_fpath)
        ##
        html = engine.render(fname, {:entries => entries})
        ok_(called) == true
        ok_(File.mtime(fragcache_fpath)) > mtime+5*60-1
        ok_(html) == expected_output2
        ok_(_read_file(fragcache_fpath)) == expected_cache2
      end
      spec "if template file is updated then block is called again" do
        ## update template timestamp
        #t = Time.now + 1
        sleep(1)
        t = Time.now
        File.utime(t, t, fname)
        ##
        called = false
        entries = proc { called = true; ['Haruhi', 'Mikuru', 'Yuki', 'Kyon', 'Itsuki'] }
        html = engine.render(fname, {:entries => entries})
        ok_(called) == true
        ok_(html) == expected_output3
        ok_(_read_file(fragcache_fpath)) == expected_cache3
      end
    ensure
      FileUtils.rm_rf(cachedir)
      [fname, "#{fname}.cache"].each do |x|
        File.unlink(x) if File.file?(x)
      end
    end
  end

  def test_default_datacache
    spec "if datastore is not speicified then @@datastore is used instead" do
      begin
        backup = Tenjin::Engine.data_cache
        Tenjin::Engine.data_cache = store = Tenjin::FileBaseStore.new('/tmp')
        engine = Tenjin::Engine.new
        ok_(engine.data_cache).same?(store)
      ensure
        Tenjin::Engine.data_cache = backup
      end
    end
  end


  ###

  def self.before_all
    Tenjin::Engine.class_eval do
      @_methods = [ :cachename, :to_filename,
                    :_get_template_in_memory, :_get_template_in_cache, :_timestamp_changed?,
                    :_preprocess, :create_template,  :hook_context ]
      public(*@_methods)
    end
  end

  def self.after_all
    Tenjin::Engine.class_eval do
      private(*@_methods)
    end
  end

  def _write(filename, content)
    File.open(filename, 'wb') {|f| f.write(content) }
  end

  def _with_dummy_files
    engine = Tenjin::Engine.new(:path=>['_views/blog', '_views'], :postfix=>'.rbhtml')
    begin
      FileUtils.mkdir_p('_views/blog')
      _write('_views/blog/index.rbhtml', 'xxx')
      _write('_views/index.rbhtml', '<<#{{@dummy_value}}>>')
      _write('_views/layout.rbhtml', '<div>#{_content}</div>')
      yield(engine)
    ensure
      FileUtils.rm_rf('_views')
    end
  end

  def test__template_cache
    engine = Tenjin::Engine.new()
    spec "if cache is nil or true then return @@template_cache" do
      expected = Tenjin::Engine.template_cache
      ok_(engine.__send__(:_template_cache, nil)).same?(expected)
      ok_(engine.__send__(:_template_cache, true)).same?(expected)
    end
    spec "if cache is false tehn return NullemplateCache object" do
      ok_(engine.__send__(:_template_cache, false)).is_a?(Tenjin::NullTemplateCache)
    end
    spec "if cache is an instnce of TemplateClass then return it" do
      eval 'class FooTemplateCache < Tenjin::TemplateCache; end'
      cache = FooTemplateCache.new
      ok_(engine.__send__(:_template_cache, cache)).same?(cache)
    end
    spec "if else then raises error" do
      f = proc { engine.__send__(:_template_cache, "hoge") }
      ok_(f).raise?(ArgumentError, ":cache is expected true, false, or TemplateCache object")
    end
  end

  def test_cachename
    engine = Tenjin::Engine.new
    fpath = 'foobar.rbhtml'.taint
    spec "return cache file name which is untainted." do
      ok_(fpath.tainted?) == true
      ret = engine.cachename(fpath)
      ok_(ret) == fpath + '.cache'
      ok_(ret.tainted?) == false
    end
    spec "if lang is provided then add it to cache filename." do
      engine.lang = 'en'
      ok_(engine.cachename(fpath)) == 'foobar.rbhtml.en.cache'
    end
  end

  def test_to_filename
    engine = Tenjin::Engine.new(:prefix=>'views/', :postfix=>'.rbhtml')
    spec "if template_name is a Symbol, add prefix and postfix to it." do
      ok_(engine.to_filename(:index)) == "views/index.rbhtml"
    end
    spec "if template_name is not a Symbol, just return it." do
      ok_(engine.to_filename('index')) == 'index'
    end
  end

  def test_register_template
    engine = Tenjin::Engine.new(:postfix=>'.rbhtml')
    template = Tenjin::Template.new(nil)
    spec "register template object without file path." do
      engine.register_template(:foo, template)
      ok_(engine.instance_variable_get('@_templates')) == {'foo.rbhtml'=>[template, nil]}
      ok_(engine.get_template(:foo)) == template
    end
  end

  def test__timestamp_changed?
    _with_dummy_files do |engine|
      e = engine
      t = Tenjin::Template.new('_views/index.rbhtml')
      mtime = File.mtime('_views/index.rbhtml')
      spec "if checked within a sec, skip timestamp check and return false." do
        t.timestamp = mtime + 30
        ok_(e._timestamp_changed?(t)) == true
        t._last_checked_at = Time.now - 0.5
        ok_(e._timestamp_changed?(t)) == false
      end
      spec "if timestamp is same as file, return false." do
        t._last_checked_at = nil
        t.timestamp = mtime
        ok_(e._timestamp_changed?(t)) == false
        ok_(t._last_checked_at.to_f).in_delta?(Time.now.to_f, 0.001)
      end
      spec "if timestamp is changed, return true." do
        t._last_checked_at = nil
        t.timestamp = mtime + 1
        ok_(e._timestamp_changed?(t)) == true
      end
    end
  end

  def test__get_template_in_memory
    fname = 'index.rbhtml'
    fpath = '_views/blog/index.rbhtml'
    _with_dummy_files do |engine|
      e = engine
      t = Tenjin::Template.new(fpath)
      _templates = e.instance_variable_get('@_templates')
      spec "if template object is not in memory cache then return nil." do
        ok_(e._get_template_in_memory(fname)) == nil
      end
      spec "if without filepath, don't check timestamp and return it." do
        _templates[fname] = ["foo", nil]
        ok_(e._get_template_in_memory(fname)) == "foo"
      end
      spec "if timestamp of template file is not changed, return it." do
        _templates[fname] = [t, fpath]
        t.timestamp = File.mtime(fpath)
        ok_(e._get_template_in_memory(fname)) == t
      end
      spec "if timestamp of template file is changed, clear it and return nil." do
        t._last_checked_at = nil
        _templates[fname] = [t, fpath]
        t.timestamp = File.mtime(fpath) + 1
        ok_(e._get_template_in_memory(fname)) == nil
        ok_(_templates[fname]) == nil
      end
    end
  end

  def test__get_template_in_cache
    _with_dummy_files do |engine|
      e = engine
      _templates = e.instance_variable_get('@_templates')
      fname = 'index.rbhtml'
      fpath = '_views/blog/index.rbhtml'
      cpath = '_views/blog/index.rbhtml.cache'
      t = nil
      spec "if template is not found in cache file, return nil." do
        not_ok_(cpath).exist?
        ok_(e._get_template_in_cache(fpath, cpath)) == nil
        t = e.get_template(:index)
        ok_(cpath).exist?
        t2 = e._get_template_in_cache(fpath, cpath)
        ok_(t2.filename) == t.filename
        ok_(t2.timestamp) == t.timestamp
        ok_(t2.script) == t.script
      end
      spec "if cache returns script and args then build a template object from them." do
        ok_(e.cache.load(cpath)) == [" _buf << %Q`xxx`; \n", [], File.mtime(cpath)]
        ok_(t).is_a?(Tenjin::Template)
      end
      spec "if timestamp of template is changed then ignore it." do
        t._last_checked_at = nil
        ts = Time.now + 1
        File.utime(ts, ts, cpath)
        ok_(e._get_template_in_cache(fpath, cpath)) == nil
      end
      spec "if timestamp is not changed then return it." do
        t._last_checked_at = nil
        ts = Time.now.to_i.to_f
        File.utime(ts, ts, fpath)
        File.utime(ts, ts, cpath)
        t2 = e._get_template_in_cache(fpath, cpath)
        ok_(t2).is_a?(Tenjin::Template)
        ok_(t2.filename) == fpath
        ok_(t2.timestamp.to_f) == ts
      end
    end
  end

  def test_get_template
    _with_dummy_files do |engine|
      e = engine
      _templates = e.instance_variable_get('@_templates')
      fname = "index.rbhtml"
      fpath = "_views/blog/index.rbhtml"
      cpath = "_views/blog/index.rbhtml.cache"
      #fpath = "#{Dir.pwd}/_views/blog/index.rbhtml"
      pre_cond { not_ok_(cpath).exist? }
      t = nil
      spec "accept template name such as :index" do
        t = e.get_template(:index)
        ok_(t.filename) == '_views/blog/index.rbhtml'
      end
      spec "if template object is memory cache then return it." do
        pre_cond { ok_(_templates[fname].first).same?(t) }
        pre_cond { ok_(t.timestamp) == File.mtime(fpath) }
        ok_(e.get_template(:index)).same?(t)
        sleep 1
        ok_(e.get_template(:index)).same?(t)
      end
      spec "if template is cached in file then store it into memory and return it." do
        _templates.clear()        # clear memory cache
        File.open(cpath, 'wb') {|f| f.write("\#@ARGS \n\nSOS") } # change cache content
        mtime = File.mtime(fpath) # make timestamps to the same value
        File.utime(mtime, mtime, cpath)
        t2 = e.get_template(:index)
        ok_(t2.script) == "\nSOS"
        ok_(_templates) == {"index.rbhtml" => [t2, "_views/blog/index.rbhtml"]}
      end
      spec "if template file is not found then raise TemplateNotFoundError" do
        errmsg = 'index2.rbhtml: template not found (path=["_views/blog", "_views"]).'
        ok_(proc { e.get_template(:index2) }).raise?(Tenjin::TemplateNotFoundError, errmsg)
      end
      spec "if @preprocess is true then preprocess template file" do
        e2 = Tenjin::Engine.new(:preprocess=>true)
        t2 = e2.get_template('_views/index.rbhtml', {:dummy_value=>'ZOZ'})
        ok_(t2.script) == ' _buf << %Q`<<ZOZ>>`; ' + "\n"
      end
      t1 = t2 = nil
      spec "if template is not found in memory nor cache then create new one." do
        t1 = e.get_template(:index)
        File.unlink(cpath)                      # remove cache file
        ok_(e.get_template(:index)).same?(t1)
        not_ok_(cpath).exist?
        _templates.clear()                      # clear memory cache
        t2 = e.get_template(:index)
        ok_(t2).is_a?(Tenjin::Template)
        not_ok_(t2).same?(t1)
      end
      spec "save template object into file cache and memory cache." do
        ok_(cpath).exist?
        ok_(_templates) == {fname => [t2, fpath]}
      end
      spec "return template object." do
        ok_(t2).is_a?(Tenjin::Template)
      end
    end
  end

  def test__preprocess
    engine = Tenjin::Engine.new
    spec "preprocess input with _context and return result" do
      ret = engine._preprocess('<<#{{@name}}>>', nil, {:name=>'SOS'})
      ok_(ret) == '<<SOS>>'
    end
  end

  def test_create_template
    engine = Tenjin::Engine.new(:path=>['_views/blog', '_views'])
    t = nil
    spec "create template object and return it." do
      t1 = engine.create_template()
      t2 = engine.create_template()
      ok_(t1).is_a?(Tenjin::Template)
      ok_(t2).is_a?(Tenjin::Template)
      not_ok(t1).same?(t2)
    end
    spec "if input is specified then convert it into script." do
      t = engine.create_template("Hello ${name}!", "foo.txt")
      ok_(t.script) == ' _buf << %Q`Hello #{escape((name).to_s)}!`; ' + "\n"
      ok_(t.filename) == 'foo.txt'
    end
  end

  def test_hook_context
    engine = Tenjin::Engine.new
    ctx = nil
    spec "return context object"
    spec "if context is nil then create new Context object" do
      ctx = engine.hook_context(nil)
      ok_(ctx).is_a?(Tenjin::Context)
    end
    spec "if context is a Hash object then convert it into Context object" do
      ctx = engine.hook_context({:x=>10})
      ok_(ctx).is_a?(Tenjin::Context)
      ok_(ctx[:x]) == 10
    end
    spec "if context is an object then use it as context object" do
      obj = Object.new
      obj.extend(Tenjin::ContextHelper)
      ok_(engine.hook_context(obj)).same?(obj)
    end
    spec "set _engine attribute" do
      ok_(ctx._engine).same?(engine)
    end
    spec "set _engine attribute" do
      ok_(ctx._layout) == nil
    end
  end

  def test_render
    input1 = '<p>Hello #{@name}!</p>'
    input2 = '<p>_context.class=#{_context.class}</p>'
    input3 = '<p>@_template.class=#{@_template.class}</p>'
    input4 = "<?rb @_layout = :_layout2 ?>\n" + input1
    layout1 = '<div>#{@_content}</div>'
    layout2 = '<body>#{@_content}</body>'
    layout3 = "<?rb @_layout = :_layout2 ?>\n" +
              '<section>#{@_content}</section>'
    layout4 = '<b>@_content=#{@_content.inspect}</b>'
    engine = Tenjin::Engine.new(:path=>['_views/blog', '_views'],
                                :postfix=>'.rbhtml', :layout=>:_layout1)
    context = {:name=>'SOS'}
    _with_dummy_files do
      File.open('_views/blog/ex1.rbhtml', 'wb') {|f| f.write(input1) }
      File.open('_views/blog/ex2.rbhtml', 'wb') {|f| f.write(input2) }
      File.open('_views/blog/ex3.rbhtml', 'wb') {|f| f.write(input3) }
      File.open('_views/blog/ex4.rbhtml', 'wb') {|f| f.write(input4) }
      File.open('_views/_layout1.rbhtml', 'wb') {|f| f.write(layout1) }
      File.open('_views/_layout2.rbhtml', 'wb') {|f| f.write(layout2) }
      File.open('_views/blog/_layout3.rbhtml', 'wb') {|f| f.write(layout3) }
      File.open('_views/_layout4.rbhtml', 'wb') {|f| f.write(layout4) }
      spec "if context is a Hash object, convert it into Context object." do
        output = engine.render(:ex2, {:foo=>1})
        ok_(output) == "<div><p>_context.class=Tenjin::Context</p></div>"
      end
      spec "set template object into context (required for cache_with() helper)" do
        output = engine.render(:ex3)
        ok_(output) == "<div><p>@_template.class=Tenjin::Template</p></div>"
      end
      spec "if @_layout is specified, use it as layoute template name" do
        output = engine.render(:ex4, context)
        ok_(output) == "<body><p>Hello SOS!</p></body>"
        output = engine.render(:ex1, context, :_layout2)
        ok_(output) == "<body><p>Hello SOS!</p></body>"
      end
      spec "use default layout template if layout is true or nil" do
        expected = "<div><p>Hello SOS!</p></div>"
        ok_(engine.render(:ex1, context))       == expected
        ok_(engine.render(:ex1, context, true)) == expected
        ok_(engine.render(:ex1, context, nil))  == expected
      end
      spec "if layout is false then don't use layout template" do
        output = engine.render(:ex1, context, false)
        ok_(output) == "<p>Hello SOS!</p>"
      end
      spec "set layout name as next template name" do
        output = engine.render(:ex1, context, :_layout3)
        ok_(output) == "<body><section><p>Hello SOS!</p></section></body>"
      end
      spec "set output into @_content for layout template" do
        output = engine.render(:ex1, context, :_layout4)
        ok_(output) == '<b>@_content="<p>Hello SOS!</p>"</b>'
      end
    end
  end

end


class FileFinderTest
  include Oktest::TestCase

  def _write(filename, content)
    File.open(filename, 'wb') {|f| f.write(content) }
  end

  def _with_dummies
    finder = Tenjin::FileFinder.new
    path = ["_views/blog", "_views"]
    begin
      FileUtils.mkdir_p("_views/blog")
      _write("_views/index.rbhtml",      "AAA")
      _write("_views/blog/index.rbhtml", "BBB")
      _write("_views/layout.rbhtml",     '<<#{_content}>>')
      yield(finder, path)
    ensure
      FileUtils.rm_rf("_views")
    end
  end

  def test_find
    _with_dummies do |finder, path|
      spec "if dirs specified then find file from it." do
        ok_(finder.find('index.rbhtml', path)) == "_views/blog/index.rbhtml"
        ok_(finder.find('layout.rbhtml', path)) == "_views/layout.rbhtml"
      end
      spec "if dirs not specified then return filename if it exists." do
        ok_(finder.find('_views/index.rbhtml')) == "_views/index.rbhtml"
      end
      spec "if file not found then return nil." do
        ok_(finder.find('foo.rbhtml', path)) == nil
        ok_(finder.find('foo.rbhtml')) == nil
      end
    end
  end

  def test_timestamp
    _with_dummies do |finder, path|
      spec "return mtime of filepath." do
        ts = (Time.now - 30.0).to_i.to_f
        fpath = '_views/index.rbhtml'
        not_ok_(finder.timestamp(fpath).to_f) == ts
        File.utime(ts, ts, fpath)
        ok_(finder.timestamp(fpath).to_f) == ts
      end
    end
  end

  def test_read
    _with_dummies do |finder, path|
      spec "if file exists then return file content and mtime." do
        fpath = '_views/blog/index.rbhtml'
        ret = finder.read(fpath)
        ok_(ret) == ['BBB', File.mtime(fpath)]
      end
      spec "if file not found then return nil." do
        ok_(finder.read('hogehoge')) == nil
      end
    end
  end

end


#if defined?(Tenjin::ArrayBufferTemplate)
#  class TenjinEngine2Test < TenjinEngineTest
#    def _template_class
#      Tenjin::ArrayBufferTemplate
#    end
#  end
#end


if __FILE__ == $0
  Oktest.run_all()
end
