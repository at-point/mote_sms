# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mote_sms/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'mote_sms'
  gem.authors       = ['Lukas Westermann', 'Loris Gavillet']
  gem.email         = ['lukas.westermann@at-point.ch', 'loris@at-point.ch']
  gem.summary       = %q{Deliver SMS using MobileTechnics HTTP API.}
  gem.description   = %q{Unofficial ruby adapter for MobileTechnics HTTP Bulk SMS API.
                         Tries to mimick mail API, so users can switch e.g. ActionMailer
                         with this SMS provider.}
  gem.homepage      = 'https://at-point.ch/opensource'

  gem.files         = %w{.gitignore Gemfile Rakefile README.md mote_sms.gemspec} + Dir['**/*.{rb,pem}']
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w{lib}
  gem.version       = MoteSMS::VERSION

  gem.required_ruby_version = '>= 1.9'

  gem.add_dependency 'phony', ['>= 1.7', '< 3.0']

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', ['~> 2.4']
  gem.add_development_dependency 'webmock', ['~> 1.8.0']
  gem.add_development_dependency 'actionmailer', ['>= 4.2', '< 6']
  gem.add_development_dependency 'activejob', ['>= 4.2', '< 6']
end
