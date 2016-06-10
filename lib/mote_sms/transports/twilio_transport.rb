require 'phony'
require 'logger'

module MoteSMS
  # MoteSMS::MobileTechnicsTransport provides the implementation to
  # send messages using nth.ch bulk SMS HTTP/S API. Each customer has
  # custom endpoint (with port) and username/password.
  #
  # Examples:
  #
  #    transport = MoteSMS::TwilioTransport.new 'my sid', 'api token', '+my phone number'
  #    transport.deliver message
  #    # => ['000-791234', '001-7987324']
  #
  class TwilioTransport
    # Maximum recipients allowed by API
    MAX_RECIPIENT = 1

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    attr_reader :from_number, :options

    # Public: Create a new instance using specified endpoint, api_key
    # and password.
    #
    # endpoint - The swisscom base url of the API
    # api_key - The String with the API key.
    # from_number - The phone number to send from (mandatory @ swisscom)
    # options - The Hash with additional URL params passed to mobile techics endpoint
    #
    # Returns a new instance.
    def initialize(account_sid, auth_token, from_number = nil, options = {})
      @from_number = from_number
      @options = options

      @client = Twilio::REST::Client.new account_sid, auth_token
    end

    # Public: Delivers message using mobile technics HTTP/S API.
    #
    # message - The MoteSMS::Message instance to send.
    # options - The Hash with service specific options.
    #
    # Returns Array with sender ids.
    def deliver(message, options = {})
      raise ArgumentError, "too many recipients, max. is #{MAX_RECIPIENT}" if message.to.length > MAX_RECIPIENT

      from = message.from.present? ? message.from : @from_number

      raise ArgumentError, 'no from number given on new message or the transport given' if from.empty?

      from = Phony.format(Phony.normalize(from), format: :international_absolute, spaces: '')

      @client.messages.create(
        from: from,
        to: prepare_number(message.to),
        body: message.body
      )
    end

    private

    def prepare_number(number_list)
      Phony.format(Phony.normalize(number_list.normalized_numbers.first), format: :international_absolute, spaces: '')
    end
  end
end
