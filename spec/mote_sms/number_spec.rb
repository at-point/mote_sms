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

  context 'handles local numbers' do
    subject { described_class.new('079 700 50 90', cc: '41') }

    its(:to_s) { should == '+41 79 700 50 90' }
    its(:number) { should == '41797005090'}
    its(:to_number) { should == '41797005090' }
  end

  context 'handles numbers with NDC regexp' do
    subject { described_class.new('079 700 50 90', cc: '41', ndc: /(44|79)/) }

    its(:to_s) { should == '+41 79 700 50 90' }
    its(:number) { should == '41797005090' }
    its(:to_number) { should == '41797005090' }
  end

  context 'non conforming number' do
    it 'raises error when creating' do
      Proc.new { described_class.new('what ever?') }.should raise_error(ArgumentError, /unable to parse/i)
      Proc.new { described_class.new('0000') }.should raise_error(ArgumentError)
      Proc.new { described_class.new('123456789012345678901') }.should raise_error(ArgumentError)
    end
  end

  context 'wrong cc/ndc' do
    it 'raises error when creating instance with wrong ndc' do
      Proc.new { described_class.new('+41 44 364 35 33', cc: '41', ndc: '43') }.should raise_error(ArgumentError, /national destination/i)
    end
  end

  context 'vanity numbers' do
    subject { described_class.new('0800-vanity', vanity: true) }

    its(:to_s) { should == '0800VANITY' }
    its(:number) { should == '0800VANITY' }
    its(:to_number) { should == '0800VANITY' }
    its(:vanity?) { should be_true }

    it 'raises error if more than 11 alpha numeric chars' do
      Proc.new { described_class.new('1234567890AB', vanity: true) }.should raise_error(ArgumentError, /invalid vanity/i)
    end

    it 'can also be normal phone number' do
      num = described_class.new('0800 123 12 12', vanity: true)
      num.to_s.should == '08001231212'
      num.to_number.should == '08001231212'
    end
  end
end
