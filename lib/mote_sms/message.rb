require 'phony'

module MoteSMS

  # Represents an SMS message, currently only provides the
  # tools to build new messages, not parse incoming messages or
  # similar stuff.
  #
  class Message

    # Number or alphanumeric name of sender.
    attr_accessor :from

    # Array of recipient numbers, international format.
    attr_accessor :to

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
    def initialize(&block)
      @to = []
      instance_eval(&block) if block_given?
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
      @from = val if val
      @from
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
      @to = args.flatten
    end

    def to
      @to
    end
  end
end
