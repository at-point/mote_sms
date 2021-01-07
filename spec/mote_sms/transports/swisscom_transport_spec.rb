# frozen_string_literal: true

require 'spec_helper'
require 'cgi'
require 'mote_sms/message'
require 'mote_sms/transports/swisscom_transport'

describe MoteSMS::SwisscomTransport do
  before do
    @logger = described_class.logger
    described_class.logger = double('logger', debug: true, info: true, error: true)
  end

  after do
    described_class.logger = @logger
  end

  subject { described_class.new(endpoint, 'example', '123456') }

  let(:endpoint) { 'https://api.example.com' }
  let(:message) do
    MoteSMS::Message.new do
      to '0041 079 123 12 12'
      from 'SENDER'
      body 'Hello World, with äöü.'
    end
  end

  let(:success) do
    { body: 'OK', status: 201 }
  end

  context '#deliver' do
    it 'sends POST to endpoint with JSON body and Client ID' do
      stub_request(:post, "#{endpoint}/messaging/sms").with do |req|
        params = JSON.load(req.body)
        expect(params['text']).to eq 'Hello World, with äöü.'
        expect(params['to']).to eq '+41791231212'
      end.to_return(success)
      expect(subject.deliver(message).normalized_numbers).to eq(['41791231212'])
    end

    it 'raises error when trying to send to multiple recipients' do
      message.to << '+41 79 333 44 55'
      message.to << '+41 78 111 22 33'

      expect { subject.deliver message }.to raise_error(described_class::ServiceError, /too many recipients/)
    end

    it 'raises exception if status code is not 201' do
      stub_request(:post, "#{endpoint}/messaging/sms").to_return(status: 500)
      expect { subject.deliver message }.to raise_error(described_class::ServiceError)
    end

    it 'returns truthy on success' do
      stub_request(:post, "#{endpoint}/messaging/sms").to_return(success)
      expect(subject.deliver(message)).to be_truthy
    end

    it 'logs curl compatible output' do
      io = StringIO.new
      described_class.logger = Logger.new(io)
      stub_request(:post, "#{endpoint}/messaging/sms").to_return(success)
      subject.deliver message
      io.rewind
      expect(io.read).to include('curl -XPOST \'https://api.example.com\' -d \'{')
    end
  end
end
