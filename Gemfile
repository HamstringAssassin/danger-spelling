# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in danger-spelling.gemspec
gemspec

# Danger plugins to run as part of CI
gem 'danger-changelog', '~> 0.6.0'
gem 'danger-rubocop'
gem 'danger-undercover'
gem 'undercover'

# Gemfile
group :test do
  gem 'simplecov'
  gem 'simplecov-lcov'
end
