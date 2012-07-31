# encoding: utf-8
require 'spec_helper'
require 'cgi'
require 'mote_sms/message'
require 'mote_sms/transports/mobile_technics_transport'

describe MoteSMS::MobileTechnicsTransport do
  before do
    @logger = described_class.logger
    described_class.logger = stub(:debug => true, :info => true, :error => true)
  end

  after do
    described_class.logger = @logger
  end

  subject { described_class.new(endpoint, "example", "123456") }

  let(:endpoint) { "http://test.nth.ch" }
  let(:message) {
    MoteSMS::Message.new do
      to '0041 079 123 12 12'
      from 'SENDER'
      body 'Hello World, with äöü.'
    end
  }

  let(:success) {
    { :body => "Result_code: 00, Message OK", :status => 200, :headers => { 'X-Nth-SmsId' => '43797917' } }
  }

  context "#deliver" do
    it "sends POST to endpoint with URL encoded body" do
      stub_request(:post, endpoint).with do |req|
        params = CGI.parse(req.body)
        params['username'].should == %w{example}
        params['password'].should == %w{123456}
        params['text'].should == ['Hello World, with äöü.']
        params['call-number'].should == ['0041791231212']
      end.to_return(success)
      subject.deliver message
    end

    it 'sends message in single request to multiple recipients' do
      message.to << '+41 79 333 44 55'
      message.to << '+41 78 111 22 33'

      stub_request(:post, endpoint).with(:body => hash_including('call-number' => '0041791231212;0041793334455;0041781112233')).to_return(success)
      subject.deliver message
    end

    it 'raises exception if required parameter is missing' do
      stub_request(:post, endpoint).to_return(:body => 'Result_code: 02, call-number')
      Proc.new { subject.deliver message }.should raise_error(MoteSMS::MobileTechnicsTransport::ServiceError)
    end

    it 'raises exception if status code is not 200' do
      stub_request(:post, endpoint).to_return(:status => 500)
      Proc.new { subject.deliver message }.should raise_error(MoteSMS::MobileTechnicsTransport::ServiceError)
    end

    it 'returns message id' do
      stub_request(:post, endpoint).to_return(success)
      subject.deliver(message).should == %w{43797917}
    end

    it 'logs curl compatible output' do
      io = StringIO.new
      described_class.logger = Logger.new(io)
      stub_request(:post, endpoint).to_return(success)
      subject.deliver message
      io.rewind
      io.read.should =~ %r{curl -XPOST 'http://test.nth.ch' -d 'allow_adaption=1&}
    end
  end

  context "#options" do
    it 'can be passed in as last item in the constructor' do
      transport = described_class.new endpoint, 'user', 'pass', :allow_adaption => false, :validity => 30
      transport.options[:allow_adaption].should be_false
      transport.options[:validity].should == 30
      transport.options[:something].should be_nil
    end

    it 'should be exposed as hash' do
      subject.options[:messageid] = "test"
      subject.options[:messageid].should == "test"
    end

    it 'overrides settings from #defaults' do
      described_class.defaults[:something] = 'global'
      subject.options[:something] = 'local'

      stub_request(:post, endpoint).with(:body => hash_including('something' => 'local')).to_return(success)
      subject.deliver message
    end

    it 'is overriden by options passed to #deliver' do
      subject.options[:something] = 'local'

      stub_request(:post, endpoint).with(:body => hash_including('something' => 'deliver')).to_return(success)
      subject.deliver message, :something => 'deliver'
    end

    it 'evaluates Procs & lambdas' do
      subject.options[:messageid] = Proc.new { "test" }

      stub_request(:post, endpoint).with(:body => hash_including('messageid' => 'test')).to_return(success)
      subject.deliver message
    end

    it 'converts allow_adaption to 1 when true' do
      subject.options[:allow_adaption] = true
      stub_request(:post, endpoint).with(:body => hash_including('allow_adaption' => '1')).to_return(success)
      subject.deliver message
    end

    it 'converts allow_adaption to 0 when false' do
      subject.options[:allow_adaption] = nil
      stub_request(:post, endpoint).with(:body => hash_including('allow_adaption' => '0')).to_return(success)
      subject.deliver message
    end
  end
end
