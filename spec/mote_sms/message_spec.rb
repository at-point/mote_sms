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
    msg.to.should == %w{41791231212}
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
end
