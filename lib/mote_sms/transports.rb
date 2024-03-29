# frozen_string_literal: true

module MoteSMS
  # All transports live within mote_sms/transports, though should be
  # available in ruby as `MoteSMS::<Some>Transport`.
  autoload :SslTransport, 'mote_sms/transports/concerns/ssl_transport'
  autoload :TestTransport, 'mote_sms/transports/test_transport'
  autoload :MobileTechnicsTransport, 'mote_sms/transports/mobile_technics_transport'
  autoload :ActionMailerTransport, 'mote_sms/transports/action_mailer_transport'
  autoload :SwisscomTransport, 'mote_sms/transports/swisscom_transport'
  autoload :TwilioTransport, 'mote_sms/transports/twilio_transport'
  autoload :OBHTransport, 'mote_sms/transports/OBH_transport'
end
