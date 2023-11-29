# frozen_string_literal: true

require 'spec_helper'
require 'mote_sms/transports/test_transport'

describe MoteSMS::TestTransport do
  subject { described_class }
  before { MoteSMS.deliveries.clear }

  it 'defines global #deliveries' do
    expect(MoteSMS).to respond_to(:deliveries)
  end

  it 'appends deliveries' do
    subject.deliver 'firstMessage'
    subject.deliver 'secondMessage'
    expect(MoteSMS.deliveries).to be == %w(firstMessage secondMessage)
  end
end
