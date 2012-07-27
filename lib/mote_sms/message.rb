require 'mote_sms/number'
require 'mote_sms/number_list'

module MoteSMS

  # Represents an SMS message, currently only provides the
  # tools to build new messages, not parse incoming messages or
  # similar stuff.
  #
  class Message

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
      @from = val ? Number.new(val, :vanity => true) : nil
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
  end
end
