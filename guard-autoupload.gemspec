# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guard/autoupload/version'

Gem::Specification.new do |spec|
  spec.name          = "guard-autoupload"
  spec.version       = Guard::Autoupload::VERSION
  spec.authors       = ["Jyrki Lilja"]
  spec.email         = ["jyrki.lilja@focus.fi"]
  spec.summary       = %q{Autoupload plugin - uploads local changes to remote host.}
  spec.description   = %q{Uses either SFTP or FTP.}
  spec.homepage      = "https://github.com/jyrkij/guard-autosync"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_runtime_dependency 'guard', '~> 1.8'
  spec.add_runtime_dependency 'net-sftp', '~> 2.1'
  spec.add_runtime_dependency 'net-ssh-simple', '~> 1.6'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 10.3"
end
