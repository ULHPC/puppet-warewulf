# Class: warewulf
#
# @param version
#   Select the correct Warewulf version
#
# @param address
#   Warewulf listen address
#   This is actually used to manage tftp-server listend address
#
class profile::warewulf (
  String $version,
  String $address
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

  service { 'warewulfd':
    ensure  => 'running',
    enable  => true,
    require => [[Package['tftp-server'], Package['warewulf']]],
  }
}
