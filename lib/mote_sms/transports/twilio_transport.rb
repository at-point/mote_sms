require 'phony'
require 'logger'
require 'twilio-ruby'

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
  class TwilioTransport
    # Maximum recipients allowed by API
    MAX_RECIPIENT = 1

    # Custom exception subclass.
    ServiceError = Class.new(::Exception)

    attr_reader :from_number, :client

    # Public: Create a new instance using specified endpoint, api_key
    # and password.
    #
    # account_sid - The twilio account sid
    # auth_token - The twilio api token
    # from_number - The phone number to send from (mandatory on initialize or send message)
    #
    # Returns a new instance.
    def initialize(account_sid, auth_token, from_number = nil)
      @from_number = from_number

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

      from = message.from.present? ? message.from.to_s : from_number

      raise ArgumentError, 'no from number given on new message or the transport given' if from.empty?

      from = Phony.format(Phony.normalize(from), format: :international_absolute, spaces: '')

      messages = prepare_numbers(message.to).map do |n|
        @client.messages.create(
          from: from,
          to: n,
          body: message.body
        )
      end
      numbers = messages.map do |result|
        result.try(:to)
      end
      NumberList.new.push numbers.compact
    end

    private

    def prepare_numbers(number_list)
      number_list.normalized_numbers.map do |n|
        Phony.format(Phony.normalize(n), format: :international_absolute, spaces: '')
      end
    end
  end
end
