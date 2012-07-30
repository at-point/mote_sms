require 'httparty'
require 'phony'

module MoteSMS

  # MoteSMS::MobileTechnicsTransport provides the implementation to
  # send messages using nth.ch bulk SMS HTTP/S API. Each customer has
  # custom endpoint and username/password.
  #
  # Examples:
  #
  #    transport = MoteSMS::MobileTechnicsTransport.new 'https://mygateway.nth.ch', 'username', 'password'
  #    transport.deliver message
  #    # => ['000-791234', '001-7987324']
  #
  class MobileTechnicsTransport

    # Maximum recipients allowed by API
    MAX_RECIPIENT = 100

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    # Accessible attributes
    attr_accessor :endpoint, :username, :password

    # Public: Global default settings for sending messages.
    def self.defaults
      @@options ||= {
        :allow_adaption => 1
      }
    end

    # Public: Create a new instance using specified endpoint, username
    # and password.
    #
    # endpoint - The String with the URL (with protocol et all) to nth gateway.
    # username - The String with username.
    # password - The String with password.
    #
    # Returns a new instance.
    def initialize(endpoint, username, password)
      self.endpoint = endpoint
      self.username = username
      self.password = password
    end

    # Public: Delivers message using mobile technics HTTP/S API.
    #
    # message - The MoteSMS::Message instance to send.
    # options - The Hash with service specific options.
    #
    # Returns Array with sender ids.
    def deliver(message, options = {})
      raise ArgumentError, "Too many recipients, max. is #{MAX_RECIPIENT} (current: #{message.to.length})" if message.to.length > MAX_RECIPIENT
      resp = HTTParty.post self.endpoint, :body => post_body(message, options)
      raise ServiceError, "Endpoint did respond with #{resp.code}" unless resp.code == 200
      raise ServiceError, "Endpoint was unable to deliver message to all recipients" unless resp.body.split("\n").all? { |l| l =~ /Result_code: 00/ }

      # extract Nth-SmsIds
      resp.headers['X-Nth-SmsId'].split(',')
    end

    protected

    def post_body(message, options)
      self.class.defaults.merge(:origin => message.from.to_number).merge(options).merge(
        :username => self.username,
        :password => self.password,
        :'call-number' => message.to.normalized_numbers.map { |n| Phony.formatted(n, :format => :international_relative, :spaces => '') }.join(';'),
        :text => message.body
      )
    end
  end
end
