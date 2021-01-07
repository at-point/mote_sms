# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'mote_sms/version'

Gem::Specification.new do |gem|
  gem.name          = 'mote_sms'
  gem.version       = MoteSMS::VERSION
  gem.authors       = ['Lukas Westermann', 'Loris Gavillet', 'Philip Lehmann', 'Simon Schmid']
  gem.email         = ['lukas@at-point.ch', 'loris@at-point.ch', 'philip@at-point.ch', 'simon@at-point.ch']
  gem.summary       = 'Deliver SMS using Swisscom / MobileTechnics REST API.'
  gem.description   = 'Unofficial ruby adapter for Swisscom and MobileTechnics Bulk SMS APIs.
                         Tries to mimick mail API, so users can switch e.g. ActionMailer
                         with this SMS provider.'
  gem.homepage      = 'https://github.com/at-point/mote_sms'

  gem.files         = %w[.gitignore Gemfile Rakefile README.md mote_sms.gemspec] + Dir['**/*.{rb,pem}']
  gem.test_files    = gem.files.grep(%r{^(spec)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.5'

  gem.add_dependency 'activesupport', '>= 5'
  gem.add_dependency 'phony', '>= 2'

  gem.add_development_dependency 'actionmailer', '>= 5'
  gem.add_development_dependency 'activejob', '>= 5'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3.6'
  gem.add_development_dependency 'twilio-ruby', '>= 4.11.0', '< 5'
  gem.add_development_dependency 'webmock', '~> 1.8.0'
end
