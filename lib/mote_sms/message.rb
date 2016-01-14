require 'mote_sms/number'
require 'mote_sms/number_list'

module MoteSMS

  # Represents an SMS message, currently only provides the
  # tools to build new messages, not parse incoming messages or
  # similar stuff.
  #
  class Message

    # The transport instance to use, if not defined
    # falls back to use global MoteSMS.transport instance.
    attr_accessor :transport

    # Public: Create a new SMS message instance.
    #
    # Examples:
    #
    #    sms = MoteSMS::Message.new do
    #      from '41791112233'
    #      to '41797776655'
    #      body 'Hi there.'
    #    end
    #    sms.from # => '41791112233'
    #    sms.to # => ['41797776655']
    #    sms.body # => 'Hi there.'
    #
    # Returns a new instance.
    def initialize(transport = nil, &block)
      @transport = transport
      @to = MoteSMS::NumberList.new
      instance_eval(&block) if block_given?
    end

    # Public: Returns current SMS message body, which should
    # be something stringish.
    #
    # Returns value of body.
    attr_writer :body
    def body(val = nil)
      @body = val if val
      @body
    end

    # Public: Returns string of sender, the sender should
    # either be 11 alphanumeric characters or 20 numbers.
    #
    # Examples:
    #
    #    sms.from = '41791231234'
    #    sms.from # => '41791231234'
    #
    # Returns value of sender.
    def from(val = nil)
      self.from = val if val
      @from
    end

    # Public: Asign an instance of Number instead of the direct
    # string, so only vanity numbers are allowed.
    def from=(val)
      @from = val ? Number.new(val, vanity: true) : nil
    end

    # Public: Set to multiple arguments or array, or whatever.
    #
    # Examples:
    #
    #   sms.to = '41791231212'
    #   sms.to # => ['41791231212']
    #
    #   sms.to = ['41791231212', '41791231212']
    #   sms.to # => ['41791231212', '41791231212']
    #
    # Returns nothing.
    def to=(*args)
      @to = MoteSMS::NumberList.new.push(*args)
    end

    # Public: Returns NumberList for this message.
    #
    # Returns NumberList instance.
    def to(*numbers)
      @to.push(*numbers) unless numbers.empty?
      @to
    end

    def transport=(trans)
      Kernel.warn 'Message#transport= is deprecated and will be removed from MoteSMS'
      @transport = trans
    end

    # Public: Deliver message using defined transport, to select the correct
    # transport method uses any of these values:
    #
    # 1. if options[:transport] is defined
    # 2. falls back to self.transport
    # 3. falls back to use MoteSMS.transport (global transport)
    #
    # Returns result of transport#deliver.
    def deliver(options = {})
      Kernel.warn 'Message#deliver is deprecated and will be removed from MoteSMS. Please use #deliver_now'
      deliver_now options
    end

    def deliver_now(options = {})
      Kernel.warn 'options[:transport] in Message#deliver_now is deprecated and will be removed from MoteSMS' if options[:transport]
      transport = options.delete(:transport) || self.transport || MoteSMS.transport
      transport.deliver(self, options)
    end

    def deliver_later(options = {})
      return Kernel.warn 'options[:transport] is not supported in Message#deliveer_later' if options.delete(:transport)
      raise 'huhuhu' unless defined?(ActiveJob)
      DeliveryJob.set(options).perform_later @from.to_s, @to.normalized_numbers, @body, options
    end
  end
end
