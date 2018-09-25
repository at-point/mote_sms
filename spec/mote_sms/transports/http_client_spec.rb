require 'spec_helper'
require 'mote_sms/version'
require 'mote_sms/transports/http_client'
require 'webmock'

describe Transports::HttpClient do
  subject { described_class.new('https://example.org/') }

  context 'Certificate checks', http: true do
    context 'api.swisscom.com' do
      subject { described_class.new('https://api.swisscom.com/') }

      it 'makes a "successful" request, i.e. no HTTPS issues' do
        request = Net::HTTP::Get.new('/')
        response = subject.request(request)
        expect(response).to be_a Net::HTTPInternalServerError
      end
    end

    context 'https://bulk.mobile-gw.com:9012', http: false do
      subject { described_class.new('https://bulk.mobile-gw.com:9012') }

      it 'makes a "successful" request, i.e. no HTTPS issues' do
        stub_request(:get, "https://bulk.mobile-gw.com:9012/").
          with(headers: { 'Accept': '*/*', 'Accept-Encoding': 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent': 'Ruby/mote_sms 1.3.11'}).
          to_return(status: 200, body: '', headers: {})
        request = Net::HTTP::Get.new('/')
        response = subject.request(request)
        expect(response).to be_a Net::HTTPOK
      end
    end
  end

  context '#initialize' do
    it 'has a default user agent' do
      expect(subject.user_agent).to eq "Ruby/mote_sms #{MoteSMS::VERSION}"
    end

    it 'has no proxy by default' do
      expect(subject.proxy_address).to be_nil
      expect(subject.proxy_port).to be_nil
    end
  end

  context '#https?' do
    it 'returns true when it is a HTTPS url' do
      expect(subject.https?).to be_truthy
    end

    it 'returns false (of course) when it is just HTTP' do
      expect(described_class.new('http://foo.example.org').https?).to be_falsey
    end
  end

  context '#request' do
    let(:request) { Net::HTTP::Get.new('/') }

    before(:each) do
      stub_request(:get, 'https://example.org/')
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => "Ruby/mote_sms #{MoteSMS::VERSION}" })
        .to_return(status: 200, body: '', headers: {})
    end

    it 'submits a request and overrides the UA' do
      response = subject.request(request)
      expect(response).to be_a Net::HTTPOK
    end
  end
end
