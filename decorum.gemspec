# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'decorum/version'

Gem::Specification.new do |spec|
  spec.name          = "decorum"
  spec.version       = Decorum::VERSION
  spec.authors       = ["Erik Cameron"]
  spec.email         = ["erik.cameron@gmail.com"]
  spec.description   = %q{Tasteful decorators for Ruby.}
  spec.summary       = %q{Decorum implements the Decorator pattern (more or less) in a fairly unobtrusive way.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
