# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mote_sms/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'mote_sms'
  gem.authors       = ['Lukas Westermann', 'Loris Gavillet']
  gem.email         = ['lukas.westermann@at-point.ch', 'loris@at-point.ch']
  gem.summary       = 'Deliver SMS using Swisscom / MobileTechnics REST API.'
  gem.description   = 'Unofficial ruby adapter for Swisscom and MobileTechnics Bulk SMS APIs.
                         Tries to mimick mail API, so users can switch e.g. ActionMailer
                         with this SMS provider.'
  gem.homepage      = 'https://github.com/at-point/mote_sms'

  gem.files         = %w(.gitignore Gemfile Rakefile README.md mote_sms.gemspec) + Dir['**/*.{rb,pem}']
  gem.bindir        = 'exe'
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w(lib)
  gem.version       = MoteSMS::VERSION

  gem.required_ruby_version = '>= 2.0'

  gem.add_dependency 'phony', ['>= 1.7', '< 3.0']
  gem.add_dependency 'activesupport', ['>= 4.2', '< 6']

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', ['~> 3.6']
  gem.add_development_dependency 'webmock', ['~> 1.8.0']
  gem.add_development_dependency 'actionmailer', ['>= 4.2', '< 6']
  gem.add_development_dependency 'activejob', ['>= 4.2', '< 6']
  gem.add_development_dependency 'twilio-ruby', ['>= 4.11.0', '< 5']
end
