require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'webmock/rspec'
require 'active_job'

ActiveJob::Base.queue_adapter = :test

# Disable should syntax
RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(http: true) { WebMock.disable! }
  config.after { WebMock.enable! }
end
