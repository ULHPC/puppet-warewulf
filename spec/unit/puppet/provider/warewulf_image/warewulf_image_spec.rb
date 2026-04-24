# frozen_string_literal: true

require 'spec_helper'
require 'puppet/resource_api'

def ensure_module_defined(module_name)
  module_name.split('::').reduce(Object) do |last_module, next_module|
    last_module.const_set(next_module, Module.new) unless last_module.const_defined?(next_module, false)
    last_module.const_get(next_module, false)
  end
end

ensure_module_defined('Puppet::Provider::WarewulfImage')
require 'puppet/provider/warewulf_image/warewulf_image'

RSpec.describe Puppet::Provider::WarewulfImage::WarewulfImage do
  subject(:provider) { described_class.new }

  let(:context) { instance_double(Puppet::ResourceApi::BaseContext, 'context') }

  before do
    allow(context).to receive(:debug)
    allow(Puppet::Util::Execution).to receive(:execute)
    allow(Puppet::Util::Execution).to receive(:execute).with('which wwctl 2> /dev/null').and_return('/bin/wwctl')
  end

  describe '#get' do
    before do
      allow(Puppet::Util::Execution).to receive(:execute).with(['/bin/wwctl', 'image', 'list']).and_return(%(
IMAGE NAME
----------
rocky10-cpu:2026.04.0
rocky8-cpu:latest-202604151004
rockylinux-10
))
    end

    it 'processes resources' do
      expect(provider.get(context)).to eq [
        {
          name: 'rocky10-cpu:2026.04.0',
          ensure: 'present',
        },
        {
          name: 'rocky8-cpu:latest-202604151004',
          ensure: 'present',
        },
        {
          name: 'rockylinux-10',
          ensure: 'present',
        },
      ]
    end
  end

  describe 'create(context, name, should)' do
    it 'import an image and build the pulled image' do
      provider.create(context, 'a',
                      name: 'a', ensure: 'present',
                      build: true, syncuser: false,
                      oci_repository_url: 'registry.example.com')

      expect(Puppet::Util::Execution).to have_received(:execute)
        .with(['/bin/wwctl', 'image', 'import', 'docker://registry.example.com/a', 'a', '--build'])
    end

    it 'import and rename an image' do
      provider.create(context, 'a',
                      name: 'a', ensure: 'present',
                      build: true, syncuser: false,
                      oci_remote_name: 'toaster',
                      oci_repository_url: 'registry.example.com')

      expect(Puppet::Util::Execution).to have_received(:execute)
        .with(['/bin/wwctl', 'image', 'import', 'docker://registry.example.com/toaster', 'a', '--build'])
    end

    it 'import and skip build' do
      provider.create(context, 'a',
                      name: 'a', ensure: 'present',
                      build: false, syncuser: false,
                      oci_repository_url: 'registry.example.com')

      expect(Puppet::Util::Execution).to have_received(:execute)
        .with(['/bin/wwctl', 'image', 'import', 'docker://registry.example.com/a', 'a'])
    end

    it 'import and syncuser' do
      provider.create(context, 'a',
                      name: 'a', ensure: 'present',
                      build: true, syncuser: true,
                      oci_repository_url: 'registry.example.com')

      expect(Puppet::Util::Execution).to have_received(:execute)
        .with(['/bin/wwctl', 'image', 'import', 'docker://registry.example.com/a', 'a', '--build', '--syncuser'])
    end

    it 'import an arm64 image' do
      provider.create(context, 'a',
                      name: 'a', ensure: 'present',
                      build: true, syncuser: false,
                      platform: 'arm64',
                      oci_repository_url: 'registry.example.com')

      expect(Puppet::Util::Execution).to have_received(:execute)
        .with(['/bin/wwctl', 'image', 'import', 'docker://registry.example.com/a', 'a', '--build', '--platform', 'arm64'])
    end

    it 'import an image from a registry that require auth' do
      provider.create(context, 'a',
                      name: 'a', ensure: 'present',
                      build: true, syncuser: false,
                      oci_repository_url: 'registry.example.com',
                      oci_repository_username: 'toto',
                      oci_repository_password: 'tata')

      expect(Puppet::Util::Execution).to have_received(:execute)
        .with(['/bin/wwctl', 'image', 'import', 'docker://registry.example.com/a', 'a', '--build', '--username', 'toto', '--password', 'tata'])
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      provider.delete(context, 'foo')
      expect(Puppet::Util::Execution).to have_received(:execute)
        .with(['/bin/wwctl', 'image', 'delete', 'foo', '--yes'])
    end
  end
end
