# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "valkyrie/moab/version"

Gem::Specification.new do |spec|
  spec.name          = "valkyrie-moab"
  spec.version       = Valkyrie::Moab::VERSION
  spec.authors       = ["Stuart Kenny"]
  spec.email         = ["kennystu@gmail.com"]

  spec.summary       = "Moab backend for Valkyrie"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'valkyrie', '2.1.1'
  spec.add_dependency 'moab-versioning', '4.3.0'

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "bixby"
  spec.add_development_dependency 'rubocop', '~> 0.48.0'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'open4'
end
