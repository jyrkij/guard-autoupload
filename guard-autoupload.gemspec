# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
    s.name        = "guard-autoupload"
    s.version     = "0.4.1"
    s.authors     = ["Jyrki Lilja"]
    s.email       = ["jyrki dot lilja at outlook dot com"]
    s.homepage    = "https://github.com/jyrkij/guard-autosync"
    s.summary     = %q{Autoupload plugin - uploads local changes to remote host.}
    s.description = %q{Uses either SFTP or FTP.}

    s.rubyforge_project = "guard-autoupload"

    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
    s.require_paths = ["lib"]

    s.add_dependency('guard')
    s.add_dependency('net-sftp')
    s.add_dependency('net-ssh-simple')
end
