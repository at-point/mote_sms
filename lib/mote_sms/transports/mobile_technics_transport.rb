require 'uri'
require 'net/http'
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
  #    transport = MoteSMS::MobileTechnicsTransport.new 'https://mygateway.nth.ch', 'username', 'password'
  #    transport.deliver message
  #    # => ['000-791234', '001-7987324']
  #
  class MobileTechnicsTransport
    # Maximum recipients allowed by API
    MAX_RECIPIENT = 100

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    # Readable attributes
    attr_reader :endpoint, :username, :password, :options, :http_client

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
      @options ||= {
        allow_adaption: true
      }
    end

    # Public: Logger used to log HTTP requests to mobile
    # technics API endpoint.
    #
    # Returns Logger instance.
    def self.logger
      @logger ||= ::Logger.new($stdout)
    end

    # Public: Change the logger used to log all HTTP requests to
    # the endpoint.
    #
    # logger - The Logger instance, should at least respond to #debug, #error.
    #
    # Returns nothing.
    def self.logger=(logger)
      @logger = logger
    end

    # Public: Create a new instance using specified endpoint, username
    # and password.
    #
    # username - The String with username.
    # password - The String with password.
    # options - The Hash with additional URL params passed to mobile techics endpoint
    #           :endpoint - The String with the URL, defaults to https://mygateway.nth.ch
    #           :ssl - SSL client options
    #
    # Returns a new instance.
    def initialize(endpoint, username, password, options = {})
      @endpoint = URI.parse(endpoint)
      @username = username
      @password = password

      @options = self.class.defaults.merge(options)

      @http_client = Transports::HttpClient.new(endpoint,
        proxy_address: @options[:proxy_address],
        proxy_port: @options[:proxy_port],
        ssl: @options[:ssl])
    end

    # Public: Delivers message using mobile technics HTTP/S API.
    #
    # message - The MoteSMS::Message instance to send.
    # options - The Hash with service specific options.
    #
    # Returns Array with sender ids.
    def deliver(message, deliver_options = {})
      raise ArgumentError, "too many recipients, max. is #{MAX_RECIPIENT} (current: #{message.to.length})" if message.to.length > MAX_RECIPIENT

      request = Net::HTTP::Post.new(endpoint.request_uri).tap do |req|
        req.body = URI.encode_www_form post_params(message, options.merge(deliver_options))
        req.content_type = 'application/x-www-form-urlencoded; charset=utf-8'
      end

      self.class.logger.debug "curl -X#{request.method} '#{endpoint}' -d '#{request.body}'"

      resp = http_client.request(request)

      raise ServiceError, "endpoint did respond with #{resp.code}" unless resp.code.to_i == 200
      raise ServiceError, "unable to deliver message to all recipients (CAUSE: #{resp.body.strip})" unless resp.body.split("\n").all? { |l| l =~ /Result_code: 00/ }

      resp['X-Nth-SmsId'].split(',')

      message.to
    end

    private

    # Internal: Prepare parameters for sending POST to endpoint, merges defaults,
    # local and per call options, adds message related informations etc etc.
    #
    # message - The MoteSMS::Message to create the POST body for.
    # options - The Hash with additional, per delivery options.
    #
    # Returns Array with params.
    def post_params(message, options)
      params = options.reject { |key, v| [:proxy_address, :proxy_port, :ssl].include?(key) }
      params.merge! username: self.username,
                    password: self.password,
                    origin: message.from ? message.from.to_number : params[:origin],
                    text: message.body,
                    :'call-number' => prepare_numbers(message.to)

      # Post process params (Procs & allow_adaption)
      params.map do |param, value|
        value = value.call(message) if value.respond_to?(:call)
        value = value ? 1 : 0 if param == :allow_adaption

        [param.to_s, value.to_s] if value
      end.compact
    end

    # Internal: Convert NumberList instance to ; separated string with international
    # relative formatted numbers. Formatting is done using phony.
    #
    # number_list - The NumberList instance.
    #
    # Returns String with numbers separated by ;.
    def prepare_numbers(number_list)
      number_list.normalized_numbers.map { |n| Phony.formatted(n, format: :international_relative, spaces: '') }.join(';')
    end
  end
end
