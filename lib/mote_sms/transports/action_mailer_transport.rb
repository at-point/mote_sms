require 'action_mailer'

module MoteSMS
  # Internal: ActionMailer class to forward SMS to recipient.
  class ActionMailerSMSMailer < ::ActionMailer::Base
    def forward_sms(recipient, sms, subject = nil)
      subject ||= "SMS to #{sms.to.map(&:to_s).join(', ')}"
      mail to: recipient, from: "#{sms.from} <#{recipient}>", subject: subject, body: sms.body
    end
  end

  # MoteSMS::ActionMailerTransport provides a transport implementation which
  # can be used in development to forward SMS as e-mails. This allows to test
  # sending SMSes to an e-mail endpoint.
  #
  # Examples:
  #
  #    # => forwards all SMS to sms@example.com
  #    MoteSMS.transport = MoteSMS::ActionMailerTransport.new "sms@example.com"
  #
  #    # => also accepts a Proc as recipient
  #    MoteSMS.transport = MoteSMS::ActionMailerTransport.new ->(msg) { "#{msg.from}@example.com" }
  #
  class ActionMailerTransport
    # Public: Read/change the recipient used when delivering the message.
    #         Read/change the from field used when delivering the message.
    # Also accepts a Proc.
    attr_accessor :recipient, :default_options

    # Public: Create a new ActionMailerTransport instance
    def initialize(recipient, default_options = {})
      self.recipient = recipient
      self.default_options = default_options
    end

    # Public: Sends message using ActionMailer to recipient.
    #
    # message - The MoteSMS::Message instance to deliver.
    # options - The Hash with additional, transport specific options.
    #
    # Returns nothing.
    def deliver(message, options = {})
      options = options.reverse_merge default_options
      to = recipient.respond_to?(:call) ? recipient.call(message) : recipient
      message.body message.body.encode(options[:encoding]) if options[:encoding].presence
      ActionMailerSMSMailer.forward_sms(to, message, options[:subject].presence).deliver_now
      message.to
    end
  end
end
