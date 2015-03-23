# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apollo/version'

Gem::Specification.new do |spec|
  spec.name          = "apollo"
  spec.version       = Apollo::VERSION
  spec.authors       = ['Brendan Tobolaski']
  spec.email         = ['brendan@signalvine.com']

  spec.summary       = 'A gem for interacting with remote hosts in various ways'
  spec.homepage      = 'https://github.com/signalvine/apollo'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'minitest', '~> 5.5.1'

  spec.add_dependency 'rabbitmq_manager', '~> 0.3.0'
  spec.add_dependency 'net-ssh', '~> 2.9.2'
end
