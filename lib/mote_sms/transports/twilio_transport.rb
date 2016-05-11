require 'phony'
require 'twilio-ruby'

require 'mote_sms/message'

module MoteSMS

  # Wrapper for twilio-ruby gem.
  class TwilioTransport
    # Maximum recipients supported
    MAX_RECIPIENT = 1

    attr_reader :client, :from_number

    def initialize(account_sid, auth_token, from_number = nil)
      @client = Twilio::REST::Client.new(account_sid, auth_token)
      @from_number = from_number
    end

    # Public: Delivers message using mobile technics HTTP/S API.
    #
    # message - The MoteSMS::Message instance to send.
    # options - The Hash with service specific options.
    #
    # Returns Array with sender ids.
    def deliver(message, options = {})
      raise ArgumentError, "too many recipients, max. is #{MAX_RECIPIENT} (current: #{message.to.length})" if message.to.length > MAX_RECIPIENT

      @client.messages.create(
        from: (message.from || from_number).to_s,
        to: fetch_number(message.to),
        body: message.body)
    end

    private

    def fetch_number(number_list)
      number_list.normalized_numbers.first.to_s
    end
  end
end
