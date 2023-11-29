# frozen_string_literal: true

module MoteSMS
  # Public: Provide access to global array of delivered
  # messages, this can be used in testing to assert sent
  # SMS messages, test their contents, recipients etc.
  #
  # Must be cleared manually (!)
  @@deliveries = []
  def self.deliveries
    @@deliveries
  end

  # MoteSMS::TestTransport provides a transport implementation which
  # can be used in test cases. This allows to test sending SMSes
  # et all without depending on an API or accidentally sending out
  # messages to real people.
  #
  # It works similar to testing ActionMailers, all delivered messages
  # will be appended to `MoteSMS.deliveries`. This array must be
  # cleared manually, so it makes sense to add a before hook to
  # your favorite testing framework:
  #
  #    before do
  #      MoteSMS.transport = MoteSMS::TestTransport
  #      MoteSMS.deliveries.clear
  #    end
  #
  module TestTransport
    # Public: Appends supplied message to global deliveries array.
    #
    # message - The MoteSMS::Message instance to deliver.
    # options - The Hash with additional, transport specific options.
    #
    # Returns nothing.
    def self.deliver(message, _options = {})
      MoteSMS.deliveries << message
    end
  end
end
