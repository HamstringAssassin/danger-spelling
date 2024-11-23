# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spelling/gem_version'

Gem::Specification.new do |spec|
  spec.name          = 'danger-spelling'
  spec.version       = Spelling::VERSION
  spec.authors       = ['HamstringAssassin']
  spec.email         = ['alanoc83@gmail.com']
  spec.description   = 'A Danger plugin for pyspelling.'
  spec.summary       = 'danger-spelling uses pyspelling to scan files changed for spelling mistakes.'
  spec.homepage      = 'https://github.com/hamstringassassin/danger-spelling'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'danger-plugin-api', '~> 1.0'

  # General ruby development
  spec.add_development_dependency 'bundler'
  # , '~> 2.0'
  spec.add_development_dependency 'rake'
  # , '~> 13.0'

  # Testing support
  spec.add_development_dependency 'rspec'
  # , '~> 3.13'

  # Linting code and docs
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'yard'

  # Makes testing easy via `bundle exec guard`
  spec.add_development_dependency 'guard'
  # , '~> 2.19'
  spec.add_development_dependency 'guard-rspec'
  # , '~> 4.7'

  # If you want to work on older builds of ruby
  spec.add_development_dependency 'listen'
  # , '3.0.7'

  # This gives you the chance to run a REPL inside your tests
  # via:
  #
  #    require 'pry'
  #    binding.pry
  #
  # This will stop test execution and let you inspect the results
  spec.add_development_dependency 'pry'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
