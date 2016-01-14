require 'spec_helper'
require 'mote_sms'

describe MoteSMS::DeliveryJob do
  subject { described_class.new }

  context '#perform' do
    it 'creates a new message based on the params and delivers it' do
      expect_any_instance_of(MoteSMS::Message).to receive(:deliver_now).with(d: 123)
      subject.perform('SENDER', ['41791231212'], 'This is the SMS content', d: 123)
    end
  end
end
