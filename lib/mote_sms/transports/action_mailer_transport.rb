require 'action_mailer'

module MoteSMS
  # Internal: ActionMailer class to forward SMS to recipient.
  class ActionMailerSMSMailer < ::ActionMailer::Base
    def forward_sms(recipient, from, sms, subject = nil)
      subject ||= "SMS to #{sms.to.map(&:to_s).join(', ')}"
      from ||= "#{sms.from} <#{recipient}>"
      mail to: recipient, from: from, subject: subject, body: sms.body
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
    attr_accessor :recipient, :from

    # Public: Create a new ActionMailerTransport instance
    def initialize(recipient, from = nil)
      self.recipient = recipient
      self.from = from
    end

    # Public: Sends message using ActionMailer to recipient.
    #
    # message - The MoteSMS::Message instance to deliver.
    # options - The Hash with additional, transport specific options.
    #
    # Returns nothing.
    def deliver(message, options = {})
      to = recipient.respond_to?(:call) ? recipient.call(message) : recipient
      ActionMailerSMSMailer.forward_sms(to, from, message, options[:subject].presence).deliver_now

      message.to
    end
  end
end
