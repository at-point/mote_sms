require 'spec_helper'
require 'mote_sms/message'
require 'mote_sms/transports/action_mailer_transport'

describe MoteSMS::ActionMailerTransport do
  subject { described_class.new "sms@example.com" }
  let(:message) { MoteSMS::Message.new do
      from 'Sender'
      to '+41 79 123 12 12'
      body 'This is the SMS content'
    end
  }
  let(:email) { ActionMailer::Base.deliveries.last }

  before do
    ActionMailer::Base.deliveries.clear
    ActionMailer::Base.delivery_method = :test
  end

  it 'sends SMS as e-mail' do
    subject.deliver message
    email.to.should == ["sms@example.com"]
    email.from.should == ["sms@example.com"]
    email.subject.should == "SMS to +41 79 123 12 12"
    email.body.should == "This is the SMS content"
  end
end