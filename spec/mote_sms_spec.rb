require 'spec_helper'
require 'mote_sms'

describe MoteSMS do
  subject { described_class }

  it 'has a version' do
    expect(subject::VERSION).to match /\d/
  end

  context 'transport' do
    before { @current_transport = subject.transport }
    after { subject.transport = @current_transport }
    let(:transport) { double('transport') }

    it 'has no default transport' do
      expect(subject.transport).to be_nil
    end

    it 'can change global transport' do
      subject.transport = transport
      expect(subject.transport).to be == transport
    end

    context '#deliver' do
      it 'delivers quick and dirty using global transport' do
        expect(transport).to receive(:deliver).with(kind_of(MoteSMS::Message), {})
        subject.transport = transport
        subject.deliver { body 'Hello World' }
      end

      it 'raises error if block is missing' do
        expect { subject.deliver }.to raise_error(ArgumentError, /block missing/i)
      end
    end
  end
end
