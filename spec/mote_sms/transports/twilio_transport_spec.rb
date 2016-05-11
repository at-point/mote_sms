require 'spec_helper'
require 'mote_sms/transports/twilio_transport'

describe MoteSMS::TwilioTransport do
  subject { described_class.new('account', '123456', '41791110011') }

  let(:message) {
    MoteSMS::Message.new do
      to '+41790001122'
      body 'Hello World'
    end
  }

  let(:result) { Twilio::REST::Message.new('/SMS', subject.client) }

  context '#initialize' do
    it 'sets account_sid' do
      expect(subject.client.account_sid).to eq 'account'
    end
  end

  context '#deliver' do
    it 'delegates to Twilio::REST::Client#messages#create()' do
      expect(subject.client.messages).to receive(:create).with(
        from: '41791110011',
        to: '41790001122',
        body: 'Hello World'
      ) { result }

      expect(subject.deliver(message)).to be_a(Twilio::REST::Message)
    end

    it 'uses the number from the message' do
      message.from = 'OTHER'
      expect(subject.client.messages).to receive(:create).with(
        from: 'OTHER',
        to: '41790001122',
        body: 'Hello World'
      ) { result }

      expect(subject.deliver(message)).to be_a(Twilio::REST::Message)
    end
  end
end
