require 'active_support/concern'

module MoteSMS
  module SslTransport
    extend ActiveSupport::Concern

    # Path to certificates
    CERTS_PATH = File.expand_path File.join(File.dirname(__FILE__), '..', '..', 'ssl_certs')

    module ClassMethods
      # Internal: The default certificate store, adds all *CA.pem files
      # from mote_sms/ssl_certs directory.
      #
      # Returns a OpenSSL::X509::Store
      def default_cert_store
        @cert_store ||= OpenSSL::X509::Store.new.tap do |store|
          Dir["#{CERTS_PATH}/*CA.pem"].each { |c| store.add_file c }
        end
      end

      # Internal: Load a X509::Certificate based on the hostname, used to handle
      # server certificate fingerprinting.
      #
      # host - The String with the hostname
      #
      # Returns OpenSSL::X509::Certificate or nil if no certificate for this host
      #  is found
      def fingerprint_cert(host)
        cert = "#{CERTS_PATH}/#{host}.pem"
        OpenSSL::X509::Certificate.new(File.read(cert)) if File.exists?(cert)
      end
    end
  end
end
