require 'spec_helper'
require 'mote_sms/transports/test_transport'

describe MoteSMS::TestTransport do
  subject { described_class }
  before { MoteSMS.deliveries.clear }

  it 'defines global #deliveries' do
    MoteSMS.should respond_to(:deliveries)
  end

  it 'appends deliveries' do
    subject.deliver "firstMessage"
    subject.deliver "secondMessage"
    MoteSMS.deliveries.should == %w{firstMessage secondMessage}
  end
end
