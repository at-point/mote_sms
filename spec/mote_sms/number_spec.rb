require 'spec_helper'
require 'mote_sms/number'

describe MoteSMS::Number do
  context 'normalized number' do
    subject { described_class.new('41443643533') }

    its(:to_s) { should == '+41 44 364 35 33' }
    its(:number) { should == '41443643533' }
    its(:to_number) { should == '41443643533' }
  end

  context 'E164 conforming number' do
    subject { described_class.new('+41 44 3643533') }

    its(:to_s) { should == '+41 44 364 35 33' }
    its(:number) { should == '41443643533' }
    its(:to_number) { should == '41443643533' }
  end

  context 'E164 conforming number with name' do
    subject { described_class.new('Frank: +41 44 3643533', :cc => '41') }

    its(:to_s) { should == '+41 44 364 35 33' }
    its(:number) { should == '41443643533' }
    its(:to_number) { should == '41443643533' }
  end

  context 'handles local numbers' do
    subject { described_class.new('079 700 50 90', :cc => '41') }

    its(:to_s) { should == '+41 79 700 50 90' }
    its(:number) { should == '41797005090'}
    its(:to_number) { should == '41797005090' }
  end

  context 'non conforming number' do
    it 'raises error when creating' do
      Proc.new { described_class.new('what ever?') }.should raise_error(ArgumentError, /unable to parse/i)
      Proc.new { described_class.new('0000') }.should raise_error(ArgumentError, /unable to parse/i)
      Proc.new { described_class.new('123456789012345678901') }.should raise_error(ArgumentError, /unable to parse/i)
    end
  end

  context 'wrong cc/ndc' do
    it 'raises error when creating instance with wrong ndc' do
      Proc.new { described_class.new('+41 44 364 35 33', :cc => '41', :ndc => '43') }.should raise_error(ArgumentError, /national destination/i)
    end
  end

  context 'vanity numbers' do
    subject { described_class.new('VANITY', :vanity => true) }

    its(:to_s) { should == 'VANITY' }
    its(:number) { should == 'VANITY' }
    its(:to_number) { should == 'VANITY' }
    its(:vanity?) { should be_true }
  end
end
