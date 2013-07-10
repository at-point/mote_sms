require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'webmock/rspec'

# Disable should syntax
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
