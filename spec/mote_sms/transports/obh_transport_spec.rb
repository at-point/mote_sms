# frozen_string_literal: true

require 'spec_helper'
require 'twilio-ruby'
require 'mote_sms/transports/twilio_transport'
require 'mote_sms/message'

describe MoteSMS::OBHTransport do
  subject do
    described_class.new(file_fixture('obh-fake.key'), file_fixture('cert_obh-fake.pem'), 'yourAPIKey', endpoint)
  end

  let(:endpoint) { 'https://test.api' }

  let(:message) do
    MoteSMS::Message.new do
      to '+41790001122'
      body 'Hello World'
    end
  end

  context '#deliver' do

    it 'send message' do
      expect_any_instance_of(OBH::Client).to receive_message_chain(:send_sms).with(
        { to: '+41790001122',
          body: 'Hello World' }
      )
      stub_request(:post, "https://test.api/sms").to_return(status: 200, body: '', headers: {})
      expect(subject.deliver(message).normalized_numbers).to eq(['41790001122'])
    end

    it 'send message with from number' do
      message.from = '+41790002233'
      subject.message_from = true
      expect_any_instance_of(OBH::Client).to receive_message_chain(:send_sms).with(
        { from: '41790002233',
          to: '+41790001122',
          body: 'Hello World' }
      )
      stub_request(:post, "https://test.api/sms").to_return(status: 200, body: '', headers: {})
      expect(subject.deliver(message).normalized_numbers).to eq(['41790001122'])
    end
  end
end
