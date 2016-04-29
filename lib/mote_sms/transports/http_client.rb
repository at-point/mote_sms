require 'digest/sha1'
require 'net/https'
require 'active_support/security_utils'
require 'mote_sms/version'

module Transports
  # Small abstraction on top of Net::HTTP to handle things like public key pinning
  # et all.
  class HttpClient
    CERTS_PATH = File.expand_path File.join(File.dirname(__FILE__), '..', 'ssl_certs')

    def self.ssl_options
      @ssl_options ||= ->(http) {
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.verify_depth = 9
        http.cert_store = self.default_cert_store
      }
    end

    def self.default_cert_store
      @default_cert_store ||= OpenSSL::X509::Store.new.tap do |store|
        Dir["#{CERTS_PATH}/*CA.pem"].each { |c| store.add_file c }
      end
    end

    def self.fingerprint_host(host)
      pem = File.join(CERTS_PATH, "#{host}.pem")
      return unless File.exist?(pem)
      cert = OpenSSL::X509::Certificate.new(File.read(pem))
      Digest::SHA1.hexdigest(cert.to_der)
    end

    def self.default_user_agent
      "Ruby/mote_sms #{MoteSMS::VERSION}"
    end

    attr_reader :endpoint, :proxy_address, :proxy_port, :user_agent, :ssl, :fingerprint

    def initialize(endpoint, enable_fingerprint: true, ssl: self.class.ssl_options,
                   proxy_address: nil, proxy_port: nil, user_agent: self.class.default_user_agent)
      @endpoint = URI.parse(endpoint)
      @proxy_address = proxy_address
      @proxy_port = proxy_port
      @user_agent = user_agent
      @ssl = ssl
      if enable_fingerprint
        @fingerprint = ENV.fetch(
          "MOTE_SMS_#{@endpoint.host.to_s.upcase.gsub(/[\.-]/, '_')}_FINGERPRINT",
          self.class.fingerprint_host(@endpoint.host))
      end
    end

    def https?
      endpoint.scheme == 'https'
    end

    def request(request)
      request['User-Agent'] = user_agent
      build_http_client.request(request)
    end

    protected

    def build_http_client
      Net::HTTP.new(endpoint.host, endpoint.port, proxy_address, proxy_port).tap do |http|
        if https?
          http.use_ssl = true
          http.verify_callback = ->(ok, store) { verify_fingerprint(ok, store) }
          ssl.call(http) if ssl.respond_to?(:call)
        end
      end
    end

    def verify_fingerprint(ok, store)
      cert_digest = Digest::SHA1.hexdigest(store.chain.first.to_der)
      return ok if verify_fingerprint?(cert_digest)

      logger.error(
        format('[Transports::HttpClient] failed to verify %s fingerprint (ACTUAL: %s, EXPECTED: %s)',
               endpoint, digest, fingerprint))
      false
    end

    def verify_fingerprint?(digest)
      return true unless fingerprint
      ActiveSupport::SecurityUtils.secure_compare(digest, fingerprint)
    end
  end
end
