###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

require "#{File.dirname(__FILE__)}/test_all"
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



class TenjinEngineTest < Test::Unit::TestCase

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
      assert_text_equal(expected, output)

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
      assert_text_equal(expected, result)
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
      assert_text_equal(expected, result)
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
      assert_text_equal(hash['expected_html'], actual)
      ##
      sleep(1)
      content_html = hash['content_html'] + "<?rb @_layout = :layout_xhtml ?>\n"
      File.write(fname.call('content_html'), content_html)
      actual = engine.render(:content_html, context)
      assert_text_equal(hash['expected_xhtml'], actual)
      ##
      sleep(1)
      content_html = hash['content_html'] + "<?rb @_layout = false ?>\n"
      File.write(fname.call('content_html'), content_html)
      actual = engine.render(:content_html, context)
      assert_text_equal(hash['expected_nolayout'], actual)
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
      assert_text_equal(expected, output)
      assert !test(?f, 'account_create.rbhtml.cache')
      #assert !test(?f, 'account_create.rbhtml.pstore')
      assert !test(?f, 'account_form.rbhtml.cache')
      #assert !test(?f, 'account_form.rbhtml.pstore')
      ## ruby code caching
      args[:cache] = true
      engine = Tenjin::Engine.new(args)
      output = engine.render(:create, context)
      assert test(?f, 'account_create.rbhtml.cache')
      #assert !test(?f, 'account_create.rbhtml.pstore')
      assert test(?f, 'account_form.rbhtml.cache')
      #assert !test(?f, 'account_form.rbhtml.pstore')
      File.unlink('account_create.rbhtml.cache')
      File.unlink('account_form.rbhtml.cache')
      ## pstore caching
      #args[:cache] = true
      #engine = Tenjin::Engine(args)
      #output = engine.render(:create, context)
      #assert !test(?f, 'account_create.rbhtml.cache')
      #assert !test(?f, 'account_create.rbhtml.pstore')
      #assert !test(?f, 'account_form.rbhtml.cache')
      #assert !test(?f, 'account_form.rbhtml.pstore')
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
    ex = assert_raise(exception) do
      assert(!test(?f, 'content.rbhtml.cache'))
      engine = Tenjin::Engine.new(:cache=>true)
      args1 = engine.get_template('content.rbhtml').args
      assert_not_nil(args1)
      output = engine.render('content.rbhtml', context)
    end
    msg = ex.to_s.sub(/:0x[0-9a-fA-F]\w+/, ':0x12345')
    msg = msg[0, errormsg.length-1]+'>' if defined?(RBX_VERSION)
    assert_equal(errormsg, msg)
    # when cache file exist
    ex = assert_raise(NameError) do
      #File.unlink('content.rbhtml');
      assert(test(?f, 'content.rbhtml.cache'))
      engine = Tenjin::Engine.new(:cache=>true)
      args2 = engine.get_template('content.rbhtml').args
      assert_not_nil(args2)
      assert_equal(args1, args2)
      output = engine.render('content.rbhtml', context)
    end
    #assert_equal(errormsg, ex.to_s.sub(/:0x\w+>/, '>'))
    msg = ex.to_s.sub(/:0x[0-9a-fA-F]\w+/, ':0x12345')
    msg = msg[0, errormsg.length-1]+'>' if defined?(RBX_VERSION)
    assert_equal(errormsg, msg)
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
      assert_equal(args, t.args)
      assert_text_equal(script, t.script)
      cache_actual = File.read(engine.cachename(filename))
      assert_text_equal(cache, cache_actual)
    end
    #
    ## args=[x,y,z], cache=1
    for f in Dir.glob(filename+'*') do File.unlink(f) end
    File.write(filename, data["input1"])
    assert(!test(?f, cachename))
    _testproc.call(cacheflag=true, n=1)
    assert(test(?f, cachename))
    _testproc.call(cacheflag=true, n=1)
    ## args=[], cache=1
    sleep(1)
    File.write(filename, data["input2"])
    #assert(test(?f, cachename))
    _testproc.call(cacheflag=true, n=2)
    #assert(test(?f, cachename))
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
      assert_text_equal(expected, output)
    ensure
      require 'fileutils'
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
    assert_text_equal(data['expected1'], actual)
    context[:params] = {'state'=>:xx}
    actual = engine.render(:create, context)  # 2nd
    #assert_text_equal(data['expected1'], actual)
    assert_text_equal(data['expected1'].sub(/ checked="checked"/, ''), actual)
    #
    context = { :title=>'Update', :action=>'update', :params=>{'state'=>:NY} }
    actual = engine.render(:update, context)  # 1st
    assert_text_equal(data['expected2'], actual)
    context[:params] = {'state'=>:xx}
    actual = engine.render(:update, context)  # 2nd
    assert_text_equal(data['expected2'], actual)  # not changed!
    #assert_text_equal(data['expected2'].sub(/ checked="checked"/, ''), actual)
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
    assert_text_equal(expected, actual)
    #
    engine = Tenjin::Engine.new(:cache=>false, :preprocess=>true)
    actual = engine.render("index.rbhtml")
    assert_text_equal(expected, actual)
  ensure
    %w[index.rbhtml show.rbhtml].each {|x| File.unlink(x) if File.exist?(x) }
  end


  self.select_target_test()


end


#if defined?(Tenjin::ArrayBufferTemplate)
#  class TenjinEngine2Test < TenjinEngineTest
#    def _template_class
#      Tenjin::ArrayBufferTemplate
#    end
#  end
#end
