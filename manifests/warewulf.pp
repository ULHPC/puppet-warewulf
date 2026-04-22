# Class: warewulf
#
# @param version
#   Select the correct Warewulf version
#
# @param address
#   Warewulf listen address
#
# @param netmask
#   Warewulf listen address netmask
#
# @param network
#   Warewulf listen address network
#
#
class profile::warewulf (
  String $version,
  String $address,
  String $netmask,
  String $network,
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
    content => "[Socket]\nListenDatagram=\nListenDatagram=${address}:69\n",
  } -> Package['tftp-server']

  file { '/etc/warewulf/warewulf.conf':
    ensure  => 'file',
    content => template("profile/warewulf/${facts['site']}/warewulf.conf.erb"),
    require => Package['warewulf'],
  }

  exec { 'warewulf_configure':
    command     => 'wwctl configure --all',
    subscribe   => File['/etc/warewulf/warewulf.conf'],
    notify      => Service['warewulfd'],
    refreshonly => true,
  }

  service { 'warewulfd':
    ensure  => 'running',
    enable  => true,
    require => [[Package['tftp-server'], Package['warewulf'], File['/etc/warewulf/warewulf.conf']]],
  }
}
