# @summary
#   Configures the Warewulf provisioning system.
#
# This private class manages the configuration of Warewulf, including
# core configuration files, node definitions, overlays, and optional
# image management. It also integrates with system services and triggers
# necessary reconfiguration commands when configuration changes occur.
#
# This class is intended to be driven via Hiera data and should not be
# declared directly by users. It is included and managed by the main
# `warewulf` class.
#
# @param address
#   The IP address (CIDR format) used by Warewulf. This value is injected
#   into the generated `warewulf.conf`.
#
# @param config
#   Base configuration hash for Warewulf. This will be merged with
#   additional required values (e.g. `ipaddr`) before being rendered
#   into `/etc/warewulf/warewulf.conf`.
#
# @param nodeprofiles
#   Hash defining Warewulf node profiles.
#
# @param nodes
#   Hash defining individual nodes and their configuration.
#
# @param manage_images
#   Whether Warewulf images should be managed by this module.
#
# @param purge_images
#   If `true`, unmanaged `warewulf_image` resources will be purged.
#
# @param default_oci_repository_url
#   Default OCI repository URL used when defining images, unless overridden
#   per image.
#
# @param default_oci_repository_password
#   Default OCI repository password used when defining images, unless overridden
#   per image.
#
# @param default_oci_repository_username
#   Default OCI repository username used when defining images, unless overridden
#   per image.
#
# @param images
#   Image definitions, either:
#   - Hash[String, Hash]: image name => parameter hash
#   - Array[String]: list of image names (uses default parameters)
#   Only used if `manage_images` is `true`.
#
# @param overlays_repo_src
#   Git repository URL for Warewulf overlays. If provided, the repository
#   is cloned and used as the overlays source.
#
# @note
#   - If `warewulf::manage_tftp_server` is enabled, a systemd drop-in
#     configuration is created to bind the TFTP socket to the specified IP.
#   - Configuration changes trigger `wwctl configure --all`.
#   - Overlay builds are triggered automatically when relevant resources
#     change.
#   - Image resources can be managed dynamically via the defined type
#     `warewulf_image`.
#
# @example Hiera configuration
#   warewulf::config::address: '192.168.1.1/24'
#   warewulf::config::config:
#     warewulf:
#       port: 9873
#       secure: true
#   warewulf::config::nodeprofiles:
#     default:
#       comment: This profile is automatically included for each node
#       cluster name: example
#       image name: rocky10
#       runtime overlay:
#         - hosts
#         - ssh.authorized_keys
#   warewulf::config::nodes:
#     node-1:
#         profiles:
#           - default
#         ipmi:
#           ipaddr: 172.23.2.103
#         network devices:
#           default:
#             hwaddr: b8:2a:72:fd:5e:7c
#             ipaddr: 172.23.1.103
#   warewulf::config::manage_images: true
#   warewulf::config::purge_images: false
#   warewulf::config::default_oci_repository_url: 'ghcr.io/warewulf'
#   warewulf::config::images:
#     rocky-8:
#       build: true
#       syncuser: false
#       platform: 'arm64'
#       oci_remote_name: 'rocky:8'
#       oci_repository_url: 'ghcr.io/warewulf'
#       oci_repository_username: 'username'
#       oci_repository_password: 'password'
#   warewulf::config::images: # or as an array of string
#     - rocky8
#     - rocky10
#   warewulf::config::overlays_repo_src: 'https://github.com/example/warewulf-overlays.git'
#
class warewulf::config (
  Variant[Stdlib::IP::Address::V4::CIDR, Stdlib::IP::Address::V6::CIDR] $address,
  Variant[Hash, Sensitive[Hash]] $config,
  Variant[Hash, Sensitive[Hash]] $nodeprofiles,
  Variant[Hash, Sensitive[Hash]] $nodes,
  Boolean $manage_images,
  Boolean $purge_images,
  String $default_oci_repository_url,
  Optional[Sensitive[String]] $default_oci_repository_password = undef,
  Optional[String] $default_oci_repository_username = undef,
  Optional[String] $overlays_repo_src = undef,
  Optional[Variant[Sensitive[Hash[String, Optional[Hash]]],Hash[String, Optional[Hash]],Array[String]]] $images = undef,
) {
  if ($warewulf::manage_tftp_server) {
    systemd::dropin_file { 'tftp-server.conf':
      unit    => 'tftp.socket',
      content => "[Socket]\nListenDatagram=\nListenDatagram=${split($address, '/')[0]}:69\n",
    }
  }

  $warewulf_config = $config + { 'ipaddr' => $address }
  file { '/etc/warewulf/warewulf.conf':
    ensure  => 'file',
    content => regsubst(stdlib::to_yaml($warewulf_config), '\A---\s*\n', ''),
  }

  file { '/etc/warewulf/nodes.conf':
    ensure  => 'file',
    content => Sensitive(template('warewulf/nodes.conf.erb')),
    group   => 'warewulf',
    mode    => '0640',
  }

  exec { 'warewulf_configure':
    command     => 'wwctl configure --all',
    environment => 'HOME=/root',
    subscribe   => File['/etc/warewulf/warewulf.conf'],
    notify      => Service['warewulfd'],
    refreshonly => true,
  }

  if ($overlays_repo_src) {
    vcsrepo { '/usr/local/src/warewulf-overlays':
      ensure   => latest,
      provider => git,
      source   => $overlays_repo_src,
      umask    => '027',
      notify   => Exec['warewulf_overlay_build'],
    }

    file { '/var/lib/warewulf/overlays':
      ensure  => 'link',
      target  => '/usr/local/src/warewulf-overlays/overlays',
      group   => 'warewulf',
      mode    => '0750',
      require => Vcsrepo['/usr/local/src/warewulf-overlays'],
    } -> Exec['warewulf_overlay_build']
  }

  exec { 'warewulf_overlay_build':
    command     => 'wwctl overlay build',
    environment => 'HOME=/root',
    subscribe   => [Exec['warewulf_configure'], File['/etc/warewulf/nodes.conf']],
    refreshonly => true,
  }

  if ($manage_images and $images) {
    resources { 'warewulf_image': purge => $purge_images }

    $images_hash = $images ? {
      Array[String] => Hash($images.map |$img| { [$img, {}] }),
      Sensitive[Hash] => $images.unwrap,
      default       => $images,
    }

    $images_hash.each |String $image, Optional[Hash] $image_params| {
      $params = $image_params ? {
        undef => {},
        default => $image_params,
      }

      $params_with_defaults = merge({
        'oci_repository_url'      => $default_oci_repository_url,
        'oci_repository_username' => $default_oci_repository_username,
        'oci_repository_password' => $default_oci_repository_password.unwrap,
      }, $params)

      warewulf_image { $image:
        ensure                  => present,
        build                   => $params_with_defaults['build'],
        syncuser                => $params_with_defaults['syncuser'],
        platform                => $params_with_defaults['platform'],
        oci_remote_name         => $params_with_defaults['oci_remote_name'],
        oci_repository_url      => $params_with_defaults['oci_repository_url'],
        oci_repository_username => $params_with_defaults['oci_repository_username'],
        oci_repository_password => Sensitive($params_with_defaults['oci_repository_password']),
      }
    }

    File['/etc/warewulf/nodes.conf']
    -> Exec['warewulf_configure']
    -> Resources['warewulf_image']
    -> Warewulf_image <| |>
  }
}
