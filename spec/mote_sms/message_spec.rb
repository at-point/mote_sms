require 'spec_helper'

describe MoteSMS::Message do
  it 'can be constructed using a block' do
    msg = described_class.new do
      from 'SENDER'
      to '+41 79 123 12 12'
      body 'This is the SMS content'
    end
    msg.from.should == 'SENDER'
    msg.to.should == %w{41791231212}
    msg.body.should == 'This is the SMS content'
  end
end
