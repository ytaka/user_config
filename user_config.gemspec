# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "user_config/version"

Gem::Specification.new do |s|
  s.name        = "user_config"
  s.version     = UserConfig::VERSION
  s.authors     = ["Takayuki YAMAGUCHI"]
  s.email       = ["d@ytak.info"]
  s.homepage    = ""
  s.summary     = "Management of configuration files in a user's home directory"
  s.description = "The library creates, saves, and loads configuration files, which are in a user's home directory or a specified directory."

  s.rubyforge_project = "user_config"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "yard"
  # s.add_runtime_dependency "rest-client"
end
