# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/warewulf_image'

RSpec.describe 'the warewulf_image type' do
  it 'loads' do
    expect(Puppet::Type.type(:warewulf_image)).not_to be_nil
  end
end
