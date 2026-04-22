# Class: warewulf
#
# @param version
#   Select the correct Warewulf version
#
class warewulf (
  String $version
) {
  if ($facts['os']['family'] != 'RedHat') {
    fail('profile::warewulf only supports RedHat family systems')
  }

  package { 'warewulf':
    ensure => 'present',
    source => "https://github.com/warewulf/warewulf/releases/download/v${version}/warewulf-${version}-1.el${facts['os']['release']['major']}.${facts['os']['architecture']}.rpm",
  }
}
