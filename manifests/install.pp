# @summary
#   Installs the Warewulf software and optional dependencies.
#
# This private class handles the installation of Warewulf and, optionally,
# the TFTP server package. Installation is currently supported for RedHat
# family operating systems. The Warewulf package is installed from a
# version-specific remote RPM source.
#
# This class is intended to be driven via Hiera data and should not be
# declared directly by users. It is included and managed by the main
# `warewulf` class.
#
# @param enable
#   Controls whether installation is performed.
#
# @param warewulf_version
#   The version of Warewulf to install. This value is used to construct
#   the download URL for the RPM package.
#
# @param tftp_server_ensure
#   Desired state of the TFTP server package (e.g. `present`, `absent`).
#   This parameter is only used if `warewulf::manage_tftp_server` is `true`.
#
# @example Hiera configuration
#   warewulf::install::enable: true
#   warewulf::install::warewulf_version: '4.5.0'
#   warewulf::install::tftp_server_ensure: 'present'
#
class warewulf::install (
  Boolean $enable,
  String $warewulf_version,
  String $tftp_server_ensure,
) {
  if $enable {
    case fact('os.family') {
      'RedHat': {
        if ($warewulf::manage_tftp_server) {
          package { 'tftp-server':
            ensure => $tftp_server_ensure,
          }
        }

        package { 'warewulf':
          ensure => 'present',
          source => "https://github.com/warewulf/warewulf/releases/download/v${warewulf_version}/warewulf-${warewulf_version}-1.el${facts['os']['release']['major']}.${facts['os']['architecture']}.rpm",
        }
      }
      default: {
        notify { "${module_name} does not support your osfamily ${fact('os.family')}, Warewulf will not be installed automatically": }
      }
    }
  }
}
