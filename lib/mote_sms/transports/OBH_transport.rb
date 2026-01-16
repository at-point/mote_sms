require 'phony'
require 'logger'
# frozen_string_literal: true

require 'OBH/client'

module MoteSMS
  # MoteSMS::OBHTransport provides the implementation to OBH
  #
  # Examples:
  #
  #    MoteSMS.transport = MoteSMS::OBHTransport.new 'obh.key', '/cert_obh.pem', 'YouAPIKEy', 'https://test.comapi/v1'
  #    sms = MoteSMS::Message.new do
  #      to 'to_number'
  #      body 'my cool text'
  #    end
  #    sms.deliver_now
  #
  class OBHTransport
    Credentials = Struct.new(:client_key_path, :client_cert_path, :api_key)
    # Maximum recipients allowed by API
    MAX_RECIPIENT = 1

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    # attr_reader :api_endpoint, :proxy_host, :proxy_port, :locale, :logger, :credentials
    attr_accessor :message_from
    attr_reader :obh_client


    # Public: Create a new instance using specified endpoint end credentials
    #
    # @param [string] client_key_path  the path to the key file
    # @param [string] client_cert_path  the path to the certificate
    # @param [string] api_key  the api_key
    # @param [string] api_endpoint the api_endpoint
    # @param [Hash] options you can pass other client options like proxy_host, proxy_port, locale and logger.
    # Another additional options is :message_from to set if teh transporter have to use or not the `from` parameters
    # for the message, by default is false
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
        conf.ca_file = options[:ca_file]
      end
      @message_from = options[:message_from] || false
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

      # perform request
      @obh_client.send_sms(post_params(message))
      message.to
    end

    private

    # Create the message post params
    # @param [NoteSMS::Message] message
    # @return [Hash]
    def post_params(message)
      params = { to: prepare_numbers(message.to), body: message.body }
      params[:from] = message.from.to_s if @message_from
      params
    end

    def prepare_numbers(number_list)
      number_list.normalized_numbers.map { |n| Phony.formatted(n, format: :international_absolute, spaces: '') }.first
    end
  end
end
