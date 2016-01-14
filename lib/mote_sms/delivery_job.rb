module MoteSMS
  class DeliveryJob < ActiveJob::Base
    queue_as :default

    def perform(to, from, body, options)
      Message.new do
        to to
        from from
        body body
      end.deliver_now options
    end
  end
end
