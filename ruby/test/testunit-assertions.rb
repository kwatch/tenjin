###
### $Rev$
### $Release$
### $Copyright$
###

require 'test/unit'
require 'tempfile'


module Test::Unit::Assertions

  def assert_text_equal(expected, actual, message=nil, diffopt='-u', flag_cut=true)
    if expected == actual
      assert(true)
      return
    end
    if expected && actual && (expected[-1] != ?\n || actual[-1] != ?\n)
      expected += "\n"
      actual   += "\n"
    end
    begin
      expfile = Tempfile.new(".expected.")
      expfile.write(expected); expfile.flush()
      actfile = Tempfile.new(".actual.")
      actfile.write(actual);   actfile.flush()
      diff = `diff #{diffopt} #{expfile.path} #{actfile.path}`
    ensure
      expfile.close(true) if expfile
      actfile.close(true) if actfile
    end
    # cut 1st & 2nd lines
    message = (flag_cut ? diff.gsub(/\A.*\n.*\n/, '') : diff) unless message
    #raise Test::Unit::AssertionFailedError.new(message)
    assert_block(message) { false }  # or assert(false, message)
  end

  alias assert_equal_with_diff assert_text_equal    # for compatibility
  alias assert_text_equals     assert_text_equal    # for typo

#  def assert_true(val, message=nil)
#    message ||= "true is expected but got #{val.inspect}"
#    assert(val == true, message)
#  end
#
#  def assert_false(val, message=nil)
#    message ||= "false is expected but got #{val.inspect}"
#    assert(val == false, message)
#  end

  def assert_exist(path, message=nil)
    message ||= "'#{path}' doesn't exist"
    assert(File.exist?(path), message)
  end

  def assert_not_exist(path, message=nil)
    message ||= "'#{path}' exist"
    assert(! File.exist?(path), message)
  end

  def assert_file_exist(path, message=nil)
    message ||= "'#{path}' doesn't exist or not a file"
    assert(File.file?(path), message)
  end

  def assert_dir_exist(path, message=nil)
    message ||= "'#{path}' doesn't exist or not a directory"
    assert(File.file?(path), message)
  end

end
