require 'spec_helper'
require 'cgi'
require 'mote_sms/message'
require 'mote_sms/transports/mobile_technics_transport'

describe MoteSMS::MobileTechnicsTransport do
  subject { described_class.new(endpoint, "example", "123456") }

  let(:endpoint) { "http://test.nth.ch" }
  let(:message) {
    MoteSMS::Message.new do
      to '0041 079 123 12 12'
      from 'SENDER'
      body 'Hello World'
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
        params['text'].should == ['Hello World']
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
  end
end
