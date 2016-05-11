require 'spec_helper'
require 'mote_sms/transports/twilio_transport'

describe MoteSMS::TwilioTransport do
  subject { described_class.new('account', '123456') }

  let(:message) {
    MoteSMS::Message.new do
      from '+41791110011'
      to '+41790001122'
      body 'Hello World'
    end
  }

  context '#deliver' do
    before {
      expect(subject.client.messages).to receive(:create).with(
        from: '41791110011',
        to: '41790001122',
        body: 'Hello World'
      ) { Twilio::REST::Message.new('/SMS', subject.client) }
    }

    it 'delegates to Twilio::REST::Client#messages#create()' do
      expect(subject.deliver message).to be_a(Twilio::REST::Message)
    end
  end
end
