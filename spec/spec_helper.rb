require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'webmock/rspec'
require 'active_job'

ActiveJob::Base.queue_adapter = :test

# Disable should syntax
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
