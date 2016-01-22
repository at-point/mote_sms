require 'uri'
require 'net/http'
require 'phony'
require 'logger'

require 'mote_sms/transports/concerns/ssl_transport'

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
    include SslTransport

    # Maximum recipients allowed by API
    MAX_RECIPIENT = 100

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    # Readable attributes
    attr_reader :endpoint, :api_key, :options

    # Public: Global default parameters for sending messages, Procs/lambdas
    # are evaluated on #deliver. Ensure to use only symbols as keys. Contains
    # `allow_adaption: true` as default.
    #
    # Examples:
    #
    #    MoteSMS::MobileTechnicsTransports.defaults[:messageid] = ->(msg) { "#{msg.from}-#{SecureRandom.hex}" }
    #
    # Returns Hash with options.
    def self.defaults
      @@options ||= {
        allow_adaption: true,
        ssl: ->(http) {
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.verify_depth = 9
          http.cert_store = self.default_cert_store
        }
      }
    end

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

    # Public: Create a new instance using specified endpoint, api_key
    # and password.
    #
    # api_key - The String with the API key.
    # options - The Hash with additional URL params passed to mobile techics endpoint
    #           :endpoint - The String with the URL, defaults to https://mygateway.nth.ch
    #           :ssl - SSL client options
    #
    # Returns a new instance.
    def initialize(endpoint, api_key, options = nil)
      @endpoint = URI.parse(endpoint)
      @api_key = api_key
      @options = options || {}
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
      options = prepare_options options
      http = http_client options
      request = http_request message.from.to_number, post_params(message, options)

      # Log as `curl` request
      self.class.logger.debug "curl -X#{request.method} '#{endpoint}' -d '#{request.body}'"

      # Perform request
      resp = http.request(request)

      # Handle errors
      raise ServiceError, "endpoint did respond with #{resp.code} and #{resp.body}" unless resp.code.to_i == 200
      self.class.logger.debug resp.body
    end

    private

    # Internal: Prepare request including body, headers etc.
    #
    # uri - The URI from the endpoint.
    # params - The Array wifromth the attributes.
    #
    # Returns Net::HTTP::Post instance.
    def http_request(from, params)
      Net::HTTP::Post.new('/v1/messaging/sms/outbound/tel:{from}/requests').tap do |request|
        request.body = params.to_json
        request.content_type = 'application/json; charset=utf-8'
        request['Accept'] = 'application/json; charset=utf-8'
        request['client_id'] = api_key
      end
    end

    # Internal: Build new Net::HTTP instance, enables SSL if requested.
    #
    # options - The Hash with all options
    #
    # Returns Net::HTTP client instance.
    def http_client(options)
      Net::HTTP.new(endpoint.host, endpoint.port).tap do |http|
        if endpoint.instance_of?(URI::HTTPS)
          cert = self.class.fingerprint_cert(endpoint.host)
          http.use_ssl = true
          http.verify_callback = ->(ok, store) { verify_fingerprint(cert.serial, ok, store) } if cert
          options[:ssl].call(http) if options[:ssl].respond_to?(:call)
        end
      end
    end

    # Public: Verify SSL server certifcate when a certificate is available in
    # mote_sms/ssl_certs/{host}.pem. Implemented to return false if first
    # certificate in chain does not match the expected serial.
    #
    # serial - The expected server certificates serial
    # ok - The Boolean forwarded by verify_callback
    # store - The OpenSSL::X509::Store instance with the chain
    #
    # Returns Boolean
    def verify_fingerprint(serial, ok, store)
      return false unless store.chain.first.serial == serial
      ok
    end

    # Internal: Merge defaults from class and instance with options
    # supplied to #deliver. Removes `:http` options, because those
    # are only for the HTTP client to set ssl verify mode et all.
    #
    # options - The Hash to merge with #defaults and #options.
    #
    # Returns Hash.
    def prepare_options(options)
      options = self.class.defaults.merge(self.options).merge(options)
    end

    # Internal: Prepare parameters for sending POST to endpoint, merges defaults,
    # local and per call options, adds message related informations etc etc.
    #
    # message - The MoteSMS::Message to create the POST body for.
    # options - The Hash with additional, per delivery options.
    #
    # Returns Array with params.
    def post_params(message, options)
      {
        outboundSMSMessageRequest: {
          senderAddress: "tel:#{message.from.to_number}",
          address: prepare_numbers(message.to),
          outboundSMSTextMessage: { message: message.body },
          clientCorrelator: options[:messageid]
        }.compact
      }
    end

    # Internal: Convert NumberList instance to ; separated string with international
    # relative formatted numbers. Formatting is done using phony.
    #
    # number_list - The NumberList instance.
    #
    # Returns String with numbers separated by ;.
    def prepare_numbers(number_list)
      number_list.normalized_numbers.map { |n| 'tel:' + Phony.formatted(n, format: :international_absolute, spaces: '') }
    end
  end
end
