require 'spec_helper'
require 'mote_sms/message'

describe MoteSMS::Message do
  it 'can be constructed using a block' do
    msg = described_class.new do
      from 'SENDER'
      to '+41 79 123 12 12'
      body 'This is the SMS content'
    end
    msg.from.number.should == 'SENDER'
    msg.to.normalized_numbers.should == %w{41791231212}
    msg.body.should == 'This is the SMS content'
  end

  context '#to' do
    it 'behaves as accessor' do
      subject.to = '41791231212'
      subject.to.normalized_numbers.should == %w{41791231212}
    end

    it 'behaves as array' do
      subject.to << '41791231212'
      subject.to << '41797775544'
      subject.to.normalized_numbers.should == %w{41791231212 41797775544}
    end

    it 'normalizes numbers' do
      subject.to = '+41 79 123 12 12'
      subject.to.normalized_numbers.should == %w{41791231212}
    end
  end

  context "#deliver" do
    let(:transport) { double("Some Transport") }
    subject { described_class.new(transport) }

    it "sends messages to transport" do
      transport.should_receive(:deliver).with(subject, {})
      subject.deliver
    end

    it "can pass additional attributes to transport" do
      transport.should_receive(:deliver).with(subject, serviceid: "myapplication")
      subject.deliver serviceid: "myapplication"
    end

    it "can override per message transport using :transport option" do
      transport.should_not_receive(:deliver)
      subject.deliver transport: double(deliver: true)
    end

    it "uses global MoteSMS.transport if no per message transport defined" do
      message = described_class.new
      transport.should_receive(:deliver).with(message, {})
      MoteSMS.should_receive(:transport) { transport }
      message.deliver
    end
  end
end
