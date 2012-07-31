require 'httparty'
require 'phony'

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

    # Accessible attributes
    attr_accessor :endpoint, :username, :password

    # Options are readable as hash
    attr_reader :options

    # Public: Global default settings for sending messages.
    def self.defaults
      @@options ||= {
        :allow_adaption => true
      }
    end

    # Public: Create a new instance using specified endpoint, username
    # and password.
    #
    # endpoint - The String with the URL (with protocol et all) to nth gateway.
    # username - The String with username.
    # password - The String with password.
    # options - The Hash with additional options.
    #
    # Returns a new instance.
    def initialize(endpoint, username, password, options = nil)
      self.endpoint = endpoint
      self.username = username
      self.password = password
      @options = options || {}
    end

    # Public: Delivers message using mobile technics HTTP/S API.
    #
    # message - The MoteSMS::Message instance to send.
    # options - The Hash with service specific options.
    #
    # Returns Array with sender ids.
    def deliver(message, options = {})
      raise ArgumentError, "Too many recipients, max. is #{MAX_RECIPIENT} (current: #{message.to.length})" if message.to.length > MAX_RECIPIENT
      resp = HTTParty.post self.endpoint, :body => post_params(message, options)
      raise ServiceError, "Endpoint did respond with #{resp.code}" unless resp.code == 200
      raise ServiceError, "Endpoint was unable to deliver message to all recipients" unless resp.body.split("\n").all? { |l| l =~ /Result_code: 00/ }

      # extract Nth-SmsIds
      resp.headers['X-Nth-SmsId'].split(',')
    end

    protected

    # Internal: Merge defaults from class and instance with options
    # supplied to #deliver.
    #
    # options - The Hash to merge with #defaults and #options.
    #
    # Returns Hash.
    def prepare_options(options)
      self.class.defaults.merge(self.options).merge(options)
    end

    # Internal: Convert NumberList instance to ; separated string with international
    # relative formatted numbers. Formatting is done using phony.
    #
    # number_list - The NumberList instance.
    #
    # Returns String with numbers separated by ;.
    def prepare_numbers(number_list)
      number_list.normalized_numbers.map { |n| Phony.formatted(n, :format => :international_relative, :spaces => '') }.join(';')
    end

    # Internal: Prepare parameters for sending POST to endpoint, merges defaults,
    # local and per call options, adds message related informations etc etc.
    #
    # message - The MoteSMS::Message to create the POST body for.
    # options - The Hash with additional, per delivery options.
    #
    # Returns Hash with POST body parameters.
    def post_params(message, options)
      params = prepare_options options
      params.merge! :username => self.username,
                    :password => self.password,
                    :origin => message.from ? message.from.to_number : params[:origin],
                    :text => message.body,
                    :'call-number' => prepare_numbers(message.to)

      # Post process params
      params = params.map do |param, value|
        value = value.call(message) if value.respond_to?(:call)
        value = value ? 1 : 0 if param == :allow_adaption
        [param, value]
      end

      # Convert back into hash
      Hash[*params.flatten]
    end
  end
end
