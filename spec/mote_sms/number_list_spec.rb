require 'spec_helper'
require 'mote_sms/number_list'

describe MoteSMS::NumberList do
  it 'can add numbers by string' do
    subject << '+41 79 111 22 33'
    subject.normalized_numbers.should == %w{41791112233}
  end

  it 'can multiple numbers using push' do
    subject.push '+41 79 111 22 33', '+41 44 111 22 33'
    subject.normalized_numbers.should == %w{41791112233 41441112233}
  end

  it 'can push multiple numbers with adding country codes' do
    subject.push '079 111 22 33', '0041 44 111 22 33', :cc => '41', :ndc => /(44|79)/
    subject.normalized_numbers.should == %w{41791112233 41441112233}
  end
end
