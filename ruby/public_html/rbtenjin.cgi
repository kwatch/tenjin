#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

##
## CGI script to use Tenjin as PHP-like tool.
##
## setup:
##
##    $ tar xzf rbtenjin-X.X.X.tar.gz
##    $ cd rbtenjin-X.X.X/
##    $ cp lib/tenjin.rb ~/public_html/
##    $ cd public_html/
##    $ cp rbtenjin.cgi .htaccess *.rbhtml ~/public_html/
##    $ chmod a+x ~/public_html/rbtenjin.cgi
##    $ cat ~/public_html/.htaccess
##    RewriteEngine on
##    RewriteRule \.(rb|rbhtml|cache)$ - [R=404,L]
##    RewriteCond %{SCRIPT_FILENAME} !-f
##    RewriteRule \.html$ rbtenjin.cgi
##    RewriteRule ^$ rbtenjin.cgi
##    RewriteRule /$ rbtenjin.cgi
##
##
## $Release: $
## $Copyright: copyright(c) 2007-2010 kuwata-lab.com all rights reserved. $
## $License: MIT License $
##

require 'tenjin'
include Tenjin::ContextHelper
include Tenjin::HtmlHelper

opts = {}
opts[:templateclass] = Tenjin::Template   # or Tenjin::SafeTemplate
opts[:layout] = '_layout.rbhtml' if File.file?('_layout.rbhtml')
opts[:cache] = false     # or true for performance
#opts[:preprocess] = true
@engine = Tenjin::Engine.new(opts)

@headers = {}
@debug = ENV['SERVER_ADDR'] == '::1'   # set debug mode true when on localhost

class HttpError < Exception
  def initialize(status, text, headers=nil)
    super("#{status}: #{text}")
    @status, @text, @headers = status, text, headers
  end
  attr_accessor :status, :text, :headers
end

begin

  ## simulate CGI in command-line to debug your *.rbhtml file
  #ENV['SCRIPT_NAME'] = '/A/B/rbtenjin.cgi'
  #ENV['REQUEST_URI'] = '/A/B/hello.html'

  ## get script name and request path
  script_name = ENV['SCRIPT_NAME']  or     # ex. '/A/B/rbtenjin.cgi'
    raise HttpError.new('500 Internal Error', "ENV['SCRIPT_NAME'] is not set.")
  req_uri     = ENV['REQUEST_URI']  or     # ex. '/A/B/C/foo.html?x=1'
    raise HttpError.new('500 Internal Error', "ENV['REQUEST_URI'] is not set.")
  req_path, _ = req_uri.split(/\?/, 2)     # ex. ['/A/B/C/foo.html', 'x=1']

  ## deny direct access to rbtenjin.cgi
  req_path != script_name  or
    raise HttpError.new('403 Forbidden', "#{req_path}: not accessable.")

  ## assert request path
  base_path = File.dirname(script_name)  # ex. '/A/B'
  req_path.index(base_path) == 0  or
    raise "*** assertion failed: #{req_path.inspect}.index(#{base_path.inspect}) == #{req_path.index(base_path)}"

  ## normalize request path and redirect if necessary
  req_path2 = req_path.dup
  req_path2.gsub!(/\\/, '/')      # ex. '\A\B\C' -> '/A/B/C'
  req_path2.gsub!(/\/\/+/, '/')   # ex. '/A///B//C' -> '/A/B/C'
  #nil while req_path2.gsub!(%r`/[^\/]+/\.\./`, '/')  # ex. '/A/../B' -> '/B'
  req_path == req_path2  or
    raise HttpError.new('302 Found', req_path2, 'Location'=>req_path2)

  ## if file_path is a directory, add 'index.html'
  file_path = req_path[(base_path.length+1)..-1]  # ex. 'C/foo.html'
  if file_path.to_s.empty?                   # access to root dir
    file_path = "index.html"
  elsif File.directory?(file_path)           # access to directory
    file_path[-1] == '/'  or
      raise "*** assertion failed: #{file_path.inspect}[-1] == '/'"
    file_path << "index.html"
  end

  ## request validation
  file_path.sub!(/\.html\z/, '.rbhtml')  or   # expected '*.html'
    raise HttpError.new('500 Internal Error', 'invalid .htaccess configuration.')
  File.file?(file_path)  or                   # file not found
    raise HttpError.new('404 Not Found', "#{req_path}: not found.")
  File.basename(file_path) !~ /\A_/  or       # deny access to '_*' (ex. _layout.rbhtml)
    raise HttpError.new('403 Forbidden', "#{req_path}: not accessable.")

  ## render template
  output = @engine.render(file_path, self)

  ## print response header and body
  print "Status: #{@headers.delete('Status')}\r\n" if @headers['Status']
  @headers.each {|k, v| print "#{k}: #{v}\r\n" }
  print "Content-Type: text/html\r\n"          unless @headers['Content-Type']
  print "Content-Length: #{output.length}\r\n" unless @headers['Content-Length']
  print "\r\n"
  print output

rescue HttpError => ex
  print "Status: #{h(ex.status)}\r\n"
  ex.headers.each {|k, v| print "#{k}: #{v}\r\n" } if ex.headers
  print "Content-Type: text/html\r\n"
  print "\r\n"
  print "<h1>#{h(ex.status)}</h1>\n"
  print "<p>#{h(ex.text)}</p>\n"

rescue Exception => ex
  $stderr.puts "*** #{ex.class.name}: #{ex.message}"
  $stderr.puts ex.backtrace.join("\n")
  print "Status: 500 Internal Error\r\n"
  print "Content-Type: text/html\r\n"
  print "\r\n"
  print "<h1>500 Internal Error</h1>\n"
  if @debug
    print "<h3>#{h(ex.class.name)}: #{h(ex.message)}</h3>\n"
    print "<style type=\"text/css\">\n"
    print "  pre.backtrace { font-size: large; }\n"
    print "  span.from { color: #933; }\n"
    print "  span.line { color: #333; }\n"
    print "  span.first { font-weight: bold; font-size: x-large; }\n"
    print "</style>\n"
    print "<pre class=\"backtrace\">\n"
    klass = ' first'
    lines = {}
    ex.backtrace.each do |item|
      print "    <span class=\"from#{klass}\">from #{h(item)}</span>\n"
      if item =~ /^(.*?):(\d+)/
        filename, linenum = $1, $2.to_i
        #line = File.open(filename) {|f| f.to_a[linenum-1] }
        lines[filename] ||= File.open(filename) {|f| f.to_a }
        line = lines[filename][linenum-1]
        print "        <span class=\"line#{klass}\">%4d: %s</span>\n" % [linenum, h(line.strip)]
      end
      klass = ''
    end
    print "</pre>\n"
  end

end
