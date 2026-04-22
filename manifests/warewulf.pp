# Class: warewulf
#
# @param version
#   Select the correct Warewulf version
#
# @param address
#   Warewulf listen address 
#   The address is in the CIDR format
#
# @param overlays_repo_src
#   The git url of the overlays repository
#
# @param oci_username
#   Username used to connect to the OCI registry
#
# @param oci_password
#   Password used to connect to the OCI registry
#
# @param nodes
#   Compute nodes configurations
# 
# @param ipmi_password
#   Compute nodes ipmi password
#
class profile::warewulf (
  String $version,
  Variant[Stdlib::IP::Address::V4::CIDR, Stdlib::IP::Address::V6::CIDR] $address,
  String $overlays_repo_src,
  Hash $nodes,
  Sensitive[String] $ipmi_password,
  Optional[String] $oci_username = undef,
  Optional[Sensitive[String]] $oci_password = undef,
) {
  if ($facts['os']['family'] != 'RedHat') {
    fail('profile::warewulf only supports RedHat family systems')
  }

  package { 'tftp-server':
    ensure => '5.2',
  }

  package { 'warewulf':
    ensure => 'present',
    source => "https://github.com/warewulf/warewulf/releases/download/v${version}/warewulf-${version}-1.el${facts['os']['release']['major']}.${facts['os']['architecture']}.rpm",
  }

  systemd::dropin_file { 'tftp-server.conf':
    unit    => 'tftp.socket',
    content => "[Socket]\nListenDatagram=\nListenDatagram=${split($address, '/')[0]}:69\n",
  } -> Package['tftp-server']

  file { '/etc/warewulf/warewulf.conf':
    ensure  => 'file',
    content => template("profile/warewulf/${facts['site']}/warewulf.conf.erb"),
    require => Package['warewulf'],
  }

  file { '/etc/warewulf/nodes.conf':
    ensure  => 'file',
    content => Sensitive(template("profile/warewulf/${facts['site']}/nodes.conf.erb")),
    group   => 'warewulf',
    mode    => '0640',
    require => Package['warewulf'],
  }

  exec { 'warewulf_configure':
    command     => 'wwctl configure --all',
    environment => 'HOME=/root',
    subscribe   => File['/etc/warewulf/warewulf.conf'],
    notify      => Service['warewulfd'],
    refreshonly => true,
  }

  vcsrepo { '/usr/local/src/warewulf-overlays':
    ensure   => latest,
    provider => git,
    source   => $overlays_repo_src,
  }

  file { '/var/lib/warewulf/overlays':
    ensure  => 'link',
    target  => '/usr/local/src/warewulf-overlays/overlays',
    require => Vcsrepo['/usr/local/src/warewulf-overlays'],
  }

  exec { 'warewulf_overlay_build':
    command     => 'wwctl overlay build',
    environment => 'HOME=/root',
    subscribe   => [Exec['warewulf_configure'], Vcsrepo['/usr/local/src/warewulf-overlays'], File['/etc/warewulf/nodes.conf']],
    refreshonly => true,
    require     => File['/var/lib/warewulf/overlays'],
  }

  service { 'warewulfd':
    ensure  => 'running',
    enable  => true,
    require => [[Package['tftp-server'], Package['warewulf'], File['/etc/warewulf/warewulf.conf']]],
  }

  file { '/root/.bash_private':
    ensure => file,
  }

  file_line { 'WAREWULF_OCI_USERNAME':
    ensure            => $oci_username ? {
      undef   => absent,
      default => present,
    },
    line              => "export WAREWULF_OCI_USERNAME='${oci_username}'",
    match             => '^export WAREWULF_OCI_USERNAME=.*$',
    path              => '/root/.bash_private',
    match_for_absence => true,
  }

  file_line { 'WAREWULF_OCI_PASSWORD':
    ensure            => $oci_password ? {
      undef   => absent,
      default => present,
    },
    line              => Sensitive("export WAREWULF_OCI_PASSWORD='${oci_password.unwrap}'"),
    match             => '^export WAREWULF_OCI_PASSWORD=.*$',
    path              => '/root/.bash_private',
    match_for_absence => true,
  }
}
