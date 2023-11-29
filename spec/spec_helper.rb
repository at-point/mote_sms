# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'webmock/rspec'
require 'active_job'
require_relative 'support/file_fixture_support'

ActiveJob::Base.queue_adapter = :test

# Disable should syntax
RSpec.configure do |config|
  config.add_setting :file_fixture_path, default: 'spec/fixtures'
  config.include FileFixtureSupport
  config.raise_errors_for_deprecations!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(http: true) { WebMock.disable! }
  config.after { WebMock.enable! }
end
