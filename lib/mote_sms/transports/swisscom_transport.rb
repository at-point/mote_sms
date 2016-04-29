require 'phony'
require 'logger'

require 'mote_sms/transports/http_client'

module MoteSMS

  # MoteSMS::MobileTechnicsTransport provides the implementation to
  # send messages using nth.ch bulk SMS HTTP/S API. Each customer has
  # custom endpoint (with port) and username/password.
  #
  # Examples:
  #
  #    transport = MoteSMS::SwisscomTransport.new 'https://api.swisscom.com/', 'ApIkEy'
  #    transport.deliver message
  #    # => ['000-791234', '001-7987324']
  #
  class SwisscomTransport
    # Maximum recipients allowed by API
    MAX_RECIPIENT = 100

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    # Readable attributes

    # Public: Logger used to log HTTP requests to mobile
    # technics API endpoint.
    #
    # Returns Logger instance.
    def self.logger
      @@logger ||= ::Logger.new($stdout)
    end

    # Public: Change the logger used to log all HTTP requests to
    # the endpoint.
    #
    # logger - The Logger instance, should at least respond to #debug, #error.
    #
    # Returns nothing.
    def self.logger=(logger)
      @@logger = logger
    end

    attr_reader :endpoint, :api_key, :from_number, :options, :http_client

    # Public: Create a new instance using specified endpoint, api_key
    # and password.
    #
    # endpoint - The swisscom base url of the API
    # api_key - The String with the API key.
    # from_number - The phone number to send from (mandatory @ swisscom)
    # options - The Hash with additional URL params passed to mobile techics endpoint
    #
    # Returns a new instance.
    def initialize(endpoint, api_key, from_number = nil, options = {})
      @endpoint = URI.parse(endpoint)
      @api_key = api_key
      @from_number = from_number
      @options = options

      @http_client = Transports::HttpClient.new(endpoint,
        proxy_address: options[:proxy_address],
        proxy_port: options[:proxy_port],
        ssl: options[:ssl])
    end

    # Public: Delivers message using mobile technics HTTP/S API.
    #
    # message - The MoteSMS::Message instance to send.
    # options - The Hash with service specific options.
    #
    # Returns Array with sender ids.
    def deliver(message, options = {})
      raise ArgumentError, "too many recipients, max. is #{MAX_RECIPIENT} (current: #{message.to.length})" if message.to.length > MAX_RECIPIENT

      # Prepare request
      request = Net::HTTP::Post.new("/messaging/v1/sms").tap do |request|
        request.body = post_params(message)
        request.content_type = 'application/json; charset=utf-8'
        request['Accept'] = 'application/json; charset=utf-8'
        request['client_id'] = api_key
      end

      # Log as `curl` request
      self.class.logger.debug "curl -X#{request.method} '#{endpoint}' -d '#{request.body}'"

      # Perform request
      resp = http.request(request)

      # Handle errors
      raise ServiceError, "endpoint did respond with #{resp.code} and #{resp.body}" unless resp.code.to_i == 201
      self.class.logger.debug resp.body
    end

    private

    def post_params(message)
      { to: prepare_numbers(message.to), text: message.body }
    end

    def prepare_numbers(number_list)
      number_list.normalized_numbers.map { |n| Phony.formatted(n, format: :international_absolute, spaces: '') }.first
    end
  end
end
