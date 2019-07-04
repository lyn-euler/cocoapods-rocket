# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-rocket/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-rocket'
  spec.version       = CocoapodsRocket::VERSION
  spec.authors       = ['asynclog']
  spec.email         = ['asynclog@163.com']
  spec.description   = %q{A short description of cocoapods-rocket.}
  spec.summary       = %q{A longer description of cocoapods-rocket.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-rocket'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency "rspec"
  spec.add_runtime_dependency 'colored2'
  spec.add_runtime_dependency 'fileutils'
  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'version_bumper'


end
