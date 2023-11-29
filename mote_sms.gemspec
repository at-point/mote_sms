# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'mote_sms/version'

Gem::Specification.new do |gem|
  gem.name          = 'mote_sms'
  gem.version       = MoteSMS::VERSION
  gem.authors       = ['Lukas Westermann', 'Loris Gavillet', 'Simon Schmid']
  gem.email         = ['info@at-point.ch']
  gem.summary       = 'Deliver SMS using Swisscom / MobileTechnics REST API.'
  gem.description   = 'Unofficial ruby adapter for Swisscom and MobileTechnics Bulk SMS APIs.
                         Tries to mimick mail API, so users can switch e.g. ActionMailer
                         with this SMS provider.'
  gem.homepage      = 'https://github.com/at-point/mote_sms'

  gem.files         = %w(.gitignore Gemfile Rakefile README.md mote_sms.gemspec) + Dir['**/*.{rb,pem}']
  gem.bindir        = 'exe'
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 3.1'

  gem.add_dependency 'phony', '>= 2'
  gem.add_dependency 'activesupport', '>= 5'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3.6'
  gem.add_development_dependency 'webmock', '~> 3.14'
  gem.add_development_dependency 'actionmailer', '>= 6.1'
  gem.add_development_dependency 'activejob', '>= 6.1'
  gem.add_development_dependency 'twilio-ruby', '~> 6'
  gem.add_development_dependency 'obh-client', '~> 0.3'
end
