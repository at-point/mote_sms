require 'httparty'
require 'phony'

module MoteSMS

  # MoteSMS::MobileTechnicsTransport provides the implementation to
  # send messages using nth.ch bulk SMS HTTP/S API. Each customer has
  # custom endpoint and username/password.
  #
  class MobileTechnicsTransport

    attr_accessor :endpoint, :username, :password

    def initialize(endpoint, username, password)
      self.endpoint = endpoint
      self.username = username
      self.password = password
    end

    def deliver(message, options = {})
      HTTParty.post self.endpoint, :body => post_body(message, options)
    end

    protected

    def post_body(message, options)
      {
        :username => self.username,
        :password => self.password,
        :origin => message.from.to_number,
        :'call-number' => message.to.normalized_numbers.map { |n| Phony.formatted(n, :format => :international_relative, :spaces => '') }.join(';'),
        :text => message.body,
        :allow_adaption => 1
      }
    end
  end
end
