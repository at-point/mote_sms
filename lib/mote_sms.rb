require 'mote_sms/transports'

module MoteSMS
  autoload :Number,      'mote_sms/number'
  autoload :NumberList,  'mote_sms/number_list'
  autoload :Message,     'mote_sms/message'
  autoload :DeliveryJob, 'mote_sms/delivery_job'

  autoload :VERSION, 'mote_sms/version'

  # No default transport.
  @@transport = nil
  @@delayed_delivery_queue = :default

  # Public: Get globally defined queue name for ActiveJob, if any.
  # Defaults to `nil`.
  #
  # Returns global ActiveJob queue name.
  def self.delayed_delivery_queue
    @@delayed_delivery_queue
  end

  # Public: Set global queue name for ActiveJob
  #
  # queue - A string or symbol that represents the queue to use for ActiveJob
  #
  # Returns nothing.
  def self.delayed_delivery_queue=(queue)
    @@delayed_delivery_queue = queue
  end

  # Public: Get globally defined transport method, if any.
  # Defaults to `nil`.
  #
  # Returns global SMS transport method.
  def self.transport
    @@transport
  end

  # Public: Set global transport method to use.
  #
  # transport - Any object which implements `#deliver(message, options)`.
  #
  # Returns nothing.
  def self.transport=(transport)
    @@transport = transport
  end

  # Public: Directly deliver a message using global transport.
  #
  # Examples:
  #
  #    MoteSMS.deliver do
  #      to '0041 79 123 12 12'
  #      from 'SENDER'
  #      body 'Hello world'
  #    end
  #
  # Returns result of #deliver.
  def self.deliver(&block)
    raise ArgumentError, 'Block missing' unless block_given?
    Message.new(&block).deliver_now
  end
end
