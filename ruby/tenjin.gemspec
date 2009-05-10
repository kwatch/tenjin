#!/usr/bin/ruby

###
### $Rev$
### $Release: $
### $Copyright$
###

require 'rubygems'

spec = Gem::Specification.new do |s|
  ## package information
  s.name        = "tenjin"
  s.author      = "makoto kuwata"
  s.email       = "kwa(at)kuwata-lab.com"
  s.rubyforge_project = 'tenjin'
  s.version     = "$Release$"
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "http://www.kuwata-lab.com/tenjin/"
  s.summary     = "very fast and full-featured template engine"
  s.description = <<-'END'
  Tenjin is a template engine and has the following features.
  * Very fast and lightweight
  * Small and only a file
  * Auto escaping support
  * Auto trimming spaces around embedded statements
  * Context object available
  * Able to load YAML data file
  * Preprocessing support
  END

  ## files
  files = []
  files += Dir.glob('lib/**/*')
  files += Dir.glob('bin/*')
  #files += Dir.glob('examples/**/*')
  files += Dir.glob('test/**/*')
  files += Dir.glob('doc/**/*')
  files += Dir.glob('examples/**/*')
  files += %w[README.txt CHANGES.txt MIT-LICENSE setup.rb tenjin.gemspec]
  #files += Dir.glob('contrib/*')
  files += Dir.glob('benchmark/**/*')
  files += Dir.glob('doc-api/**/*')
  s.files       = files
  s.executables = ['rbtenjin']
  s.bindir      = 'bin'
  s.test_file   = 'test/test_all.rb'
end

# Quick fix for Ruby 1.8.3 / YAML bug   (thanks to Ross Bamford)
if (RUBY_VERSION == '1.8.3')
  def spec.to_yaml
    out = super
    out = '--- ' + out unless out =~ /^---/
    out
  end
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
