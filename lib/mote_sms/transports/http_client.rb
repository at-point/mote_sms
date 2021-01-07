# frozen_string_literal: true

require 'uri'
require 'net/https'
require 'digest/sha1'

require 'active_support/security_utils'
require 'mote_sms/version'

module Transports
  CERTS_PATH = File.expand_path File.join(File.dirname(__FILE__), '..', 'ssl_certs')

  # Small abstraction on top of Net::HTTP to handle things like public key pinning
  # et all.
  class HttpClient
    def self.ssl_options
      @ssl_options ||= lambda do |http|
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.verify_depth = 9
        http.cert_store = OpenSSL::X509::Store.new
        http.cert_store.set_default_paths
        Dir["#{CERTS_PATH}/*.crt"].each do |c|
          http.cert_store.add_cert OpenSSL::X509::Certificate.new(File.read(c))
        rescue OpenSSL::X509::StoreError => e
          nil
        end
      end
    end

    def self.default_user_agent
      "Ruby/mote_sms #{MoteSMS::VERSION}"
    end

    attr_reader :endpoint, :proxy_address, :proxy_port, :user_agent, :ssl

    def initialize(endpoint, ssl: self.class.ssl_options,
                   proxy_address: nil, proxy_port: nil, user_agent: self.class.default_user_agent)
      @endpoint = URI.parse(endpoint)
      @proxy_address = proxy_address
      @proxy_port = proxy_port
      @user_agent = user_agent
      @ssl = ssl || self.class.ssl_options
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
          ssl.call(http) if ssl.respond_to?(:call)
        end
      end
    end
  end
end
