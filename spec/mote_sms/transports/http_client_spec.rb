require 'spec_helper'
require 'mote_sms/transports/http_client'

describe Transports::HttpClient do
  subject { described_class.new('https://example.org/') }

  context 'Certificate checks', http: true do
    context 'api.swisscom.com' do
      subject { described_class.new('https://api.swisscom.com/', enable_fingerprint: true) }

      it 'makes a "successful" request, i.e. no HTTPS issues' do
        request = Net::HTTP::Get.new('/')
        response = subject.request(request)
        expect(response).to be_a Net::HTTPInternalServerError
      end
    end

    context 'https://bulk.mobile-gw.com:9012' do
      subject { described_class.new('https://bulk.mobile-gw.com:9012', enable_fingerprint: true) }

      it 'makes a "successful" request, i.e. no HTTPS issues' do
        request = Net::HTTP::Get.new('/')
        response = subject.request(request)
        expect(response).to be_a Net::HTTPOK
      end
    end
  end

  context '#initialize' do
    before { ENV.delete('MOTE_SMS_EXAMPLE_ORG_FINGERPRINT') }

    it 'has a default user agent' do
      expect(subject.user_agent).to eq "Ruby/mote_sms #{MoteSMS::VERSION}"
    end

    it 'has no proxy by default' do
      expect(subject.proxy_address).to be_nil
      expect(subject.proxy_port).to be_nil
    end

    it 'tries to load a fingerprint via hostname, when ENV is not set' do
      expect(described_class).to receive(:fingerprint_host).with('example.org') { 'pem-fingerprint' }
      expect(subject.fingerprint).to eq 'pem-fingerprint'
    end

    it 'tries to use the ENV for a fingerprint lookup' do
      ENV['MOTE_SMS_EXAMPLE_ORG_FINGERPRINT'] = 'env-fingerprint'
      allow(described_class).to receive(:fingerprint_host) { 'pem-fingerprint' }
      expect(subject.fingerprint).to eq 'env-fingerprint'
    end

    context 'with enable_fingerprint: false' do
      subject { described_class.new('https://example.org', enable_fingerprint: false) }

      it 'can skip fingerprinting by setting enable_fingerprint: false' do
        ENV['MOTE_SMS_EXAMPLE_ORG_FINGERPRINT'] = 'env-fingerprint'
        allow(described_class).to receive(:fingerprint_host) { 'pem-fingerprint' }
        expect(subject.fingerprint).to be_nil
      end
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

    before {
      stub_request(:get, "https://example.org/").
        with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Ruby/mote_sms 1.2.0' }).
        to_return(status: 200, body: "", headers: {})
    }

    it 'submits a request and overrides the UA' do
      response = subject.request(request)
      expect(response).to be_a Net::HTTPOK
    end
  end
end
