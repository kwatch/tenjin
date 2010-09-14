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
      datacache = Tenjin::FileBaseStore.new(cachedir)
      Tenjin::Engine.datacache = datacache
      engine = Tenjin::Engine.new
          # or engine = Tenjin::Engine.new(:datacache=>datacache)
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
        t = Time.now + 1
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
        backup = Tenjin::Engine.datacache
        Tenjin::Engine.datacache = store = Tenjin::FileBaseStore.new('/tmp')
        engine = Tenjin::Engine.new
        ok_(engine.datacache).same?(store)
      ensure
        Tenjin::Engine.datacache = backup
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
