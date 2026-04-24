# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'warewulf_image',
  docs: <<~EOS,
    @summary a warewulf_image type
    @example
      warewulf_image { 'foo':
        ensure => 'present',
        oci_repository_url => 'rocky10'
      }

    This type provides Puppet with the capabilities to manage Warewulf images.
  EOS
  features: [],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this warewulf_image should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'The name of the Warewulf image.',
      behaviour: :namevar,
    },
    build: {
      type: 'Boolean',
      desc: 'Build image after pulling.',
      default: true,
      behaviour: :parameter,
    },
    syncuser: {
      type: 'Boolean',
      desc: 'Synchronize UIDs/GIDs from host to image.',
      default: false,
      behaviour: :parameter,
    },
    oci_remote_name: {
      type: 'Optional[String]',
      desc: 'The OCI name on the repository.',
      behaviour: :parameter,
    },
    oci_repository_url: {
      type: 'String',
      desc: 'The OCI repository url.',
      behaviour: :parameter,
    },
  },
)
