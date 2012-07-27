require 'spec_helper'
require 'cgi'
require 'mote_sms/message'
require 'mote_sms/transports/mobile_technics_transport'

describe MoteSMS::MobileTechnicsTransport do
  subject { described_class.new("http://example.com", "example", "123456") }
  let(:message) do
    MoteSMS::Message.new do
      to '0041 079 123 12 12'
      from 'SENDER'
      body 'Hello World'
    end
  end

  context "#deliver" do
    it "sends POST to endpoint with URL encoded body" do
      stub_request(:post, "example.com").with do |req|
        params = CGI.parse(req.body)
        params['username'].should == %w{example}
        params['password'].should == %w{123456}
        params['text'].should == ['Hello World']
        params['call-number'].should == ['0041791231212']
      end
      subject.deliver message
    end
  end
end
