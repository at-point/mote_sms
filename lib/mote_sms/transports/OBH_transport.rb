require 'phony'
require 'logger'
require 'OBH/client'

module MoteSMS
  # MoteSMS::TwilioTransport provides the implementation to
  # send messages using the Twilio Api https://github.com/twilio/twilio-ruby
  #
  # Examples:
  #
  #    MoteSMS.transport = MoteSMS::TwilioTransport.new 'sid', 'token', 'from_number'
  #    sms = MoteSMS::Message.new do
  #      to 'to_number'
  #      body 'my cool text'
  #    end
  #    sms.deliver_now
  #    # => <Twilio::REST::Message>
  #
  class OBHTransport
    Credentials = Struct.new(:client_key_path, :client_cert_path, :api_key)
    # Maximum recipients allowed by API
    MAX_RECIPIENT = 1

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    # attr_reader :api_endpoint, :proxy_host, :proxy_port, :locale, :logger, :credentials
    # attr_accessor :configuration

    attr_reader :obh_client

    # Public: Create a new instance using specified endpoint, api_key
    # and password.
    # TODO
    # account_sid - The twilio account sid
    # auth_token - The twilio api token
    # from_number - The phone number to send from (mandatory on initialize or send message)
    #
    # Returns a new instance.
    def initialize(client_key_path, client_cert_path, api_key, api_endpoint, options = {})
      @obh_client = OBH::Client.new do |conf|
        conf.credentials(client_key_path: client_key_path, client_cert_path: client_cert_path, api_key: api_key)
        conf.api_endpoint = api_endpoint
        conf.proxy_host = options[:proxy_host]
        conf.proxy_port = options[:proxy_port]
        conf.locale = options[:locale]
        conf.logger = options[:logger]
      end
    end

    # Public: Delivers message using mobile technics HTTP/S API.
    #
    # @param message - The MoteSMS::Message instance to send.
    # @param _options - The Hash with service specific options.
    #
    # @return [Array] Returns Array with sender ids.
    #
    def deliver(message, _options = {})
      raise ArgumentError, "too many recipients, max. is #{MAX_RECIPIENT}" if message.to.length > MAX_RECIPIENT

      raise ArgumentError, 'no from user given on new message or the transport given' if message.from.empty?

      # perform request
      @obh_client.send_sms(post_params(message))
      message.to
    end

    private

    def post_params(message)
      { to: prepare_numbers(message.to), body: message.body, from: message.from }
    end

    def prepare_numbers(number_list)
      number_list.normalized_numbers.map { |n| Phony.formatted(n, format: :international_absolute, spaces: '') }.first
    end

  end
end
