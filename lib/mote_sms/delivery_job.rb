require 'active_job'
require 'mote_sms/message'

module MoteSMS
  class DeliveryJob < ActiveJob::Base
    queue_as { MoteSMS.delayed_delivery_queue }

    def perform(from, to, body, options)
      Message.new do
        from from
        to to
        body body
      end.deliver_now options
    end
  end
end
