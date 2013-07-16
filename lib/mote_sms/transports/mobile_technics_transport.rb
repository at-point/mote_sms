require 'uri'
require 'net/http'
require 'phony'
require 'logger'

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

    # Path to certificates
    CERTS_PATH = File.expand_path File.join(File.dirname(__FILE__), '..', 'ssl_certs')

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    # Readable attributes
    attr_reader :endpoint, :username, :password, :options

    # Internal: The default certificate store, adds all *CA.pem files
    # from mote_sms/ssl_certs directory.
    #
    # Returns a OpenSSL::X509::Store
    def self.default_cert_store
      @cert_store ||= OpenSSL::X509::Store.new.tap do |store|
        Dir["#{CERTS_PATH}/*CA.pem"].each { |c| store.add_file c }
      end
    end

    # Internal: Load a X509::Certificate based on the hostname, used to handle
    # server certificate fingerprinting.
    #
    # host - The String with the hostname
    #
    # Returns OpenSSL::X509::Certificate or nil if no certificate for this host
    #  is found
    def self.fingerprint_cert(host)
      cert = "#{CERTS_PATH}/#{host}.pem"
      OpenSSL::X509::Certificate.new(File.read(cert)) if File.exists?(cert)
    end

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
    def initialize(endpoint, username, password, options = nil)
      @endpoint = URI.parse(endpoint)
      @username = username
      @password = password
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
      request = http_request post_params(message, options)

      # Log as `curl` request
      self.class.logger.debug "curl -X#{request.method} '#{endpoint}' -d '#{request.body}'"

      # Perform request
      resp = http.request(request)

      # Handle errors
      raise ServiceError, "endpoint did respond with #{resp.code}" unless resp.code.to_i == 200
      raise ServiceError, "unable to deliver message to all recipients (CAUSE: #{resp.body.strip})" unless resp.body.split("\n").all? { |l| l =~ /Result_code: 00/ }

      # extract Nth-SmsIds
      resp['X-Nth-SmsId'].split(',')
    end

    private

    # Internal: Prepare request including body, headers etc.
    #
    # uri - The URI from the endpoint.
    # params - The Array with the attributes.
    #
    # Returns Net::HTTP::Post instance.
    def http_request(params)
      Net::HTTP::Post.new(endpoint.request_uri).tap do |request|
        request.body = URI.encode_www_form params
        request.content_type = 'application/x-www-form-urlencoded; charset=utf-8'
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
      params = options.reject { |key, v| key == :ssl }
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
