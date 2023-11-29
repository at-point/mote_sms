# frozen_string_literal: true

require 'spec_helper'
require 'mote_sms/number_list'

describe MoteSMS::NumberList do
  it 'has length' do
    expect(subject.length).to be == 0
    subject << '+41 79 111 22 33'
    expect(subject.length).to be == 1
    5.times { subject << '+41 79 222 33 44' }
    expect(subject.length).to be == 6
  end

  it 'has empty?' do
    expect(subject.empty?).to be_truthy
    subject << '+41 79 111 22 33'
    expect(subject.empty?).to be_falsey
  end

  it 'can add numbers by string' do
    subject << '+41 79 111 22 33'
    expect(subject.normalized_numbers).to be == %w(41791112233)
  end

  it 'can multiple numbers using push' do
    subject.push '+41 79 111 22 33', '+41 44 111 22 33'
    expect(subject.normalized_numbers).to be == %w(41791112233 41441112233)
  end

  it 'can push multiple numbers with adding country codes' do
    subject.push '079 111 22 33', '0041 44 111 22 33', cc: '41', ndc: /(44|79)/
    expect(subject.normalized_numbers).to be == %w(41791112233 41441112233)
  end
end
