# frozen_string_literal: true

require 'spec_helper'
require 'twilio-ruby'
require 'mote_sms/transports/twilio_transport'
require 'mote_sms/message'

describe MoteSMS::TwilioTransport do
  subject do
    described_class.new('account', '123456', '41791110011')
  end

  let(:message) do
    MoteSMS::Message.new do
      to '+41790001122'
      body 'Hello World'
    end
  end

  let(:message) do
    MoteSMS::Message.new do
      to '+41790001122'
      body 'Hello World'
    end
  end

  context '#deliver' do
    before do
      allow_any_instance_of(Twilio::REST::Client).to receive_message_chain(:messages, :create) do |params|
        OpenStruct.new(to: params[:to])
      end
    end

    it 'send message' do
      expect_any_instance_of(Twilio::REST::Client).to receive_message_chain(:messages, :create).with(
        from: '41791110011',
        to: '+41790001122',
        body: 'Hello World'
      )
      expect(subject.deliver(message).normalized_numbers).to eq(['41790001122'])
    end

    it 'uses the number from the message' do
      message.from = '41791110033'
      expect_any_instance_of(Twilio::REST::Client).to receive_message_chain(:messages, :create).with(
        from: '41791110033',
        to: '+41790001122',
        body: 'Hello World'
      )

      expect(subject.deliver(message).normalized_numbers).to eq(['41790001122'])
    end
  end
end
