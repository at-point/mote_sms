require 'spec_helper'
require 'mote_sms'
require 'active_job'

describe MoteSMS::Message do
  it 'can be constructed using a block' do
    msg = described_class.new do
      from 'SENDER'
      to '+41 79 123 12 12'
      body 'This is the SMS content'
    end
    expect(msg.from.number).to be == 'SENDER'
    expect(msg.to.normalized_numbers).to be == %w(41791231212)
    expect(msg.body).to be == 'This is the SMS content'
  end

  context '#to' do
    it 'behaves as accessor' do
      subject.to = '41791231212'
      expect(subject.to.normalized_numbers).to be == %w(41791231212)
    end

    it 'behaves as array' do
      subject.to << '41791231212'
      subject.to << '41797775544'
      expect(subject.to.normalized_numbers).to be == %w(41791231212 41797775544)
    end

    it 'normalizes numbers' do
      subject.to = '+41 79 123 12 12'
      expect(subject.to.normalized_numbers).to be == %w(41791231212)
    end
  end

  context '#deliver' do
    subject { described_class.new }

    it 'delegates to deliver_now and deprecates it' do
      expect(subject).to receive(:deliver_now)
      expect(Kernel).to receive(:warn).with('Message#deliver is deprecated and will be removed from MoteSMS. Please use #deliver_now')
      subject.deliver
    end
  end

  context '#deliver_now' do
    let(:transport) { double('Some Transport') }
    subject do
      expect(Kernel).to receive(:warn).with('Message#new(transport) is deprecated and will be removed from MoteSMS')
      described_class.new(transport)
    end

    it 'sends messages to transport' do
      expect(transport).to receive(:deliver).with(subject, {})
      subject.deliver_now
    end

    it 'can pass additional attributes to transport' do
      expect(transport).to receive(:deliver).with(subject, serviceid: 'myapplication')
      subject.deliver_now serviceid: 'myapplication'
    end

    it 'can override per message transport using :transport option and it deprecates it' do
      expect(transport).to_not receive(:deliver)
      expect(Kernel).to receive(:warn).with('options[:transport] in Message#deliver_now is deprecated and will be removed from MoteSMS')
      subject.deliver_now transport: double(deliver: true)
    end

    it 'uses global MoteSMS.transport if no per message transport defined' do
      message = described_class.new
      expect(transport).to receive(:deliver).with(message, {})
      expect(MoteSMS).to receive(:transport) { transport }
      message.deliver_now
    end
  end

  context '#deliver_later' do
    before { MoteSMS.transport = MoteSMS::TestTransport }
    after { MoteSMS.transport = nil }

    subject do
      described_class.new do
        from 'SENDER'
        to '+41 79 123 12 12'
        body 'This is the SMS content'
      end
    end

    it 'can not override per message transport using :transport option and it deprecates it' do
      expect(Kernel).to receive(:warn).with('options[:transport] is not supported in Message#deliveer_later')
      subject.deliver_later transport: double(deliver: true)
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 1
    end

    it 'queues the delivery in the DeliveryJob' do
      subject.deliver_later
      job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
      expect(job[:job]).to eq MoteSMS::DeliveryJob
      expect(job[:args]).to include 'SENDER'
      expect(job[:args]).to include ['41791231212']
      expect(job[:args]).to include 'This is the SMS content'
    end
  end
end
