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
      @_methods = [ :cachename, :to_filename, :find_template_file,
                    :read_template_file, :create_template, :_set_template_attrs, :hook_context ]
      public *@_methods
    end
  end

  def self.after_all
    Tenjin::Engine.class_eval do
      private *@_methods
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

  def _with_dummy_files
    begin
      FileUtils.mkdir_p('_views/blog')
      File.open('_views/blog/index.rbhtml', 'w') {|f| f.write('xxx') }
      File.open('_views/index.rbhtml', 'w') {|f| f.write('<<#{{$dummy_value}}>>') }
      File.open('_views/layout.rbhtml', 'w') {|f| f.write('<div>#{_content}</div>') }
      yield
    ensure
      FileUtils.rm_rf('_views')
    end
  end

  def test_find_template_file
    _with_dummy_files do
      engine1 = Tenjin::Engine.new(:path=>['_views/blog', '_views'], :postfix=>'.rbhtml')
      engine2 = Tenjin::Engine.new(:postfix=>'.rbhtml')
      spec "if @path is provided then search template file from it." do
        ok_(engine1.find_template_file('index.rbhtml').first) == '_views/blog/index.rbhtml'
        ok_(engine1.find_template_file('layout.rbhtml').first) == '_views/layout.rbhtml'
      end
      spec "if @path is not provided then just return filename if file exists." do
        ok_(engine2.find_template_file('_views/index.rbhtml').first) == '_views/index.rbhtml'
      end
      spec "if template file is not found then raises Errno::ENOENT." do
        f = proc { engine1.find_template_file('index2.rbhtml') }
        ok_(f).raise?(Errno::ENOENT, 'No such file or directory - index2.rbhtml (path=["_views/blog", "_views"])')
        f = proc { engine2.find_template_file('_views/index2.rbhtml') }
        ok_(f).raise?(Errno::ENOENT, 'No such file or directory - _views/index2.rbhtml (path=nil)')
      end
      filepath = "_views/blog/index.rbhtml"
      #filepath = "#{Dir.pwd}/_views/blog/index.rbhtml"
      mtime = File.mtime(filepath)
      spec "return file path and mtime of template file." do
        ok_(engine1.find_template_file("index.rbhtml")) == [filepath, mtime]
      end
      spec "accept template_name such as :index" do
        ok_(engine1.find_template_file(:index)) == [filepath, mtime]
      end
    end
  end

  def test_read_template_file
    _with_dummy_files do
      $dummy_value = 'ABC'
      fpath = '_views/index.rbhtml'
      spec "if preprocessing is not enabled, just read template file and return it." do
        engine1 = Tenjin::Engine.new()
        ok_(engine1.read_template_file(fpath)) == '<<#{{$dummy_value}}>>'
      end
      spec "if preprocessing is enabled, read template file and preprocess it." do
        engine2 = Tenjin::Engine.new(:preprocess=>true)
        ok_(engine2.read_template_file(fpath)) == '<<ABC>>'
      end
    end
  end

  def test_register_template
    engine = Tenjin::Engine.new()
    template = Tenjin::Template.new(nil)
    spec "register template object without file path." do
      engine.register_template(:foo, template)
      ok_(engine.instance_variable_get('@_templates')) == {:foo=>[template, nil]}
      ok_(engine.get_template(:foo)) == template
    end
  end

  def test_create_template
    _with_dummy_files do
      engine = Tenjin::Engine.new(:path=>['_views/blog', '_views'])
      t = nil
      spec "return template object" do
        ok_(engine.create_template(nil)).is_a?(Tenjin::Template)
      end
      spec "if filepath is specified then create template from it." do
        t = engine.create_template('_views/layout.rbhtml')
        ok_(t.filename) == "_views/layout.rbhtml"
        ok_(t.script) == ' _buf << %Q`<div>#{_content}</div>`; ' + "\n"
      end
      spec "if filepath is not specified then just create empty template object." do
        t = engine.create_template(nil)
        ok_(t.filename) == nil
        ok_(t.script) == nil
      end
      spec "set timestamp of template object." do
        ts = Time.now - 5
        t = engine.create_template('_views/layout.rbhtml', ts)
        ok_(t.timestamp) == ts
        t = engine.create_template(nil, ts)
        ok_(t.timestamp) == ts
      end
      spec "if filepath is specified but not timestamp then use file's mtime as timestamp" do
        ts = Time.now - 30
        File.utime(ts, ts, '_views/layout.rbhtml')
        t = engine.create_template('_views/layout.rbhtml')
        ok_(t.timestamp.to_s) == ts.to_s
      end
    end
  end

  def test__set_template_attrs
    t = Tenjin::Template.new(nil)
    engine = Tenjin::Engine.new()
    engine.__send__(:_set_template_attrs, t, 'foobar.rbhtml', 'x=10', ['x', 'y'])
    ok_(t.filename) == 'foobar.rbhtml'
    ok_(t.script)   == 'x=10'
    ok_(t.args)     == ['x', 'y']
  end

  def test_get_template
    _with_dummy_files do
      e = Tenjin::Engine.new(:path=>['_views/blog', '_views'], :postfix=>'.rbhtml')
      _templates = e.instance_variable_get('@_templates')
      cachefile = '_views/blog/index.rbhtml.cache'
      filepath = "_views/blog/index.rbhtml"
      #filepath = "#{Dir.pwd}/_views/blog/index.rbhtml"
      pre_cond { not_ok_(cachefile).exist? }
      t = nil
      spec "return template object." do
        t = e.get_template(:index)
        ok_(t).is_a?(Tenjin::Template)
        ok_(t.filename) == filepath
      end
      spec "if template is not found in file cache, create it and save into cache file." do
        ok_(cachefile).exist?
      end
      spec "save template object into memory cache with file path." do
        ok_(_templates) == { :index => [t, filepath] }
      end
      #
      spec "if template object is in memory cache..." do
        ts = Time.now
        File.utime(ts-30, ts-30, filepath)
        File.utime(ts, ts, cachefile)
        spec "... and it's timestamp is same as file, return it." do
          t.timestamp = File.mtime(filepath)
          ok_(e.get_template(:index)).same?(t)
        end
        spec "... but it doesn't have file path, don't check timestamp." do
          t.timestamp = ts
          _templates[:index][1] = nil
          ok_(e.get_template(:index)).same?(t)
        end
      end
      #
      spec "if template object is not found in memory cache, load from file cache." do
        _templates.clear()
        ok_(_templates[:index]) == nil
        ts = File.mtime(cachefile)
        t2 = e.get_template(:index, ts)
        ok_(t2).is_a?(Tenjin::Template)
        ok_(t2.filename) == t.filename
        ok_(t2.script) == t.script
        ok_(t2.args) == t.args
        not_ok_(t2).same?(t)
      end
      spec "if file cache data is a pair of script and args, create template object from them." do
        ts = File.mtime(cachefile)
        ret = e.cache.load(cachefile, ts)
        ok_(ret).is_a?(Array)
        ok_(ret) == [" _buf << %Q`xxx`; \n", []]
      end
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
        output = 
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
