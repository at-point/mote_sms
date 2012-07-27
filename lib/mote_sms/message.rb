module Mote

  # Represents an SMS message, currently only provides the
  # tools to build new messages, not parse incoming messages or
  # similar stuff.
  #
  class Message

    #
    attr_accessor :from

    def initialize(&block)
      instance_eval(&block) if block_given?
    end
  end
end
