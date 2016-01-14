require 'spec_helper'

unless defined?(ActiveJob)
  Kernel.warn 'ATTENTION - ActiveJob is not defined, specs in delivery_job_spec.rb are not executed'
else
  require 'mote_sms/delivery_job'

  describe MoteSMS::DeliveryJob do
    context '#perform' do
      expect any_instance_of(Message).to receive(:deliver_now).with(d: 123)
      expect(Message).to receive(:new)
      subject.perform('a', 'b', 'c', d: 123)
    end
  end
end
