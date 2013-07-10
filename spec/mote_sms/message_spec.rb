require 'spec_helper'
require 'mote_sms/message'

describe MoteSMS::Message do
  it 'can be constructed using a block' do
    msg = described_class.new do
      from 'SENDER'
      to '+41 79 123 12 12'
      body 'This is the SMS content'
    end
    expect(msg.from.number).to be == 'SENDER'
    expect(msg.to.normalized_numbers).to be == %w{41791231212}
    expect(msg.body).to be == 'This is the SMS content'
  end

  context '#to' do
    it 'behaves as accessor' do
      subject.to = '41791231212'
      expect(subject.to.normalized_numbers).to be == %w{41791231212}
    end

    it 'behaves as array' do
      subject.to << '41791231212'
      subject.to << '41797775544'
      expect(subject.to.normalized_numbers).to be == %w{41791231212 41797775544}
    end

    it 'normalizes numbers' do
      subject.to = '+41 79 123 12 12'
      expect(subject.to.normalized_numbers).to be == %w{41791231212}
    end
  end

  context "#deliver" do
    let(:transport) { double("Some Transport") }
    subject { described_class.new(transport) }

    it "sends messages to transport" do
      expect(transport).to receive(:deliver).with(subject, {})
      subject.deliver
    end

    it "can pass additional attributes to transport" do
      expect(transport).to receive(:deliver).with(subject, serviceid: "myapplication")
      subject.deliver serviceid: "myapplication"
    end

    it "can override per message transport using :transport option" do
      expect(transport).to_not receive(:deliver)
      subject.deliver transport: double(deliver: true)
    end

    it "uses global MoteSMS.transport if no per message transport defined" do
      message = described_class.new
      expect(transport).to receive(:deliver).with(message, {})
      expect(MoteSMS).to receive(:transport) { transport }
      message.deliver
    end
  end
end
