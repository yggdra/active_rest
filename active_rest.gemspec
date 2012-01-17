# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_rest/version"

Gem::Specification.new do |s|
  s.name        = "active_rest"
  s.version     = ActiveRest::VERSION
  s.authors     = ["Daniele Orlandi"]
  s.email       = ["daniele@orlandi.com"]
  s.homepage    = "http://www.yggdra.it/"
  s.summary     = %q{REST controller mixin}
  s.description = %q{ActiveRest provides several useful actions for restful controllers}

  s.rubyforge_project = "active_rest"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  #s.add_runtime_dependency ''
end
