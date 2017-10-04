require 'spec_helper'
require 'twilio-ruby'
require 'mote_sms/transports/twilio_transport'
require 'mote_sms/message'

describe MoteSMS::TwilioTransport do
  subject do
    client = double(Twilio::REST::Client)
    expect(client).to receive(:messages).at_least(:once) { results }
    expect(Twilio::REST::Client).to receive(:new).with('account', '123456') { client }
    described_class.new('account', '123456', '41791110011')
  end

  let(:message) do
    MoteSMS::Message.new do
      to '+41790001122'
      body 'Hello World'
    end
  end

  let(:result) do
    Twilio::REST::Message.new('/SMS', subject.client, from: '+41791110011', to: '41790001122', body: 'Hello World')
  end
  let(:results) do
    Twilio::REST::Messages.new('/SMS', subject.client)
  end

  let(:message) do
    MoteSMS::Message.new do
      to '+41790001122'
      body 'Hello World'
    end
  end

  context '#deliver' do
    it 'send message' do
      expect(subject.client.messages).to receive(:create).with(
        from: '41791110011',
        to: '+41790001122',
        body: 'Hello World'
      ).at_least(:once) { result }

      expect(subject.deliver(message).normalized_numbers).to eq(['41790001122'])
    end

    it 'uses the number from the message' do
      message.from = '41791110033'
      expect(subject.client.messages).to receive(:create).with(
        from: '41791110033',
        to: '+41790001122',
        body: 'Hello World'
      ).at_least(:once) { result }

      expect(subject.deliver(message).normalized_numbers).to eq(['41790001122'])
    end
  end
end
