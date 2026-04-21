# frozen_string_literal: true

require 'spec_helper'
require 'facter/warewulf'

describe 'warewulf fact specs', type: :fact do
  subject(:fact) { Facter.fact(:warewulf) }

  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
    allow(Facter::Util::Resolution).to receive(:which).with('wwctl').and_return('/bin/wwctl')
  end

  describe 'warewulf' do
    before do
      allow(Facter::Core::Execution).to receive(:execute).with('/bin/wwctl image ls').and_return(%(
IMAGE NAME
----------
rocky10-cpu:2026.04.0
rocky8-cpu:latest-202604151004
rockylinux-10
))
    end

    it 'list correctly current images' do
      expect(Facter.fact(:warewulf).value['images']).to eq(['rocky10-cpu:2026.04.0', 'rocky8-cpu:latest-202604151004', 'rockylinux-10'])
    end
  end
end
