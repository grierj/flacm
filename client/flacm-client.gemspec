# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flacm/version'

Gem::Specification.new do |spec|
  spec.name          = "flacm-client"
  spec.version       = Flacm::VERSION
  spec.authors       = ["Grier Johnson"]
  spec.email         = ["grierj@gmail.com"]
  spec.description   = %q{The client for FLA Configuration Management}
  spec.summary       = %q{FLACM Client}
  spec.homepage      = "https://github.com/grierj/flacm"
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
