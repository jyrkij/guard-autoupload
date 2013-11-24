source 'https://rubygems.org'

gemspec

gem 'rake'

require 'rbconfig'
gem 'wdm', '>= 0.1.0' if RbConfig::CONFIG['target_os'] =~ /mswin|mingw|cygwin/i

group :development do
  gem 'guard'
end
