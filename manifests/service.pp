# @summary Manages the Warewulf service resource.
#
# This class is intended to be driven via Hiera data and should not be
# declared directly by users. It is included and managed by the main
# `warewulf` class.
#
# @param manage
#   Whether the service resource should be managed.
#
# @param enable
#   Whether the service should be enabled at boot.
#
# @param ensure
#   Desired state of the service (e.g. `running`, `stopped`).
#
# @param service_name
#   Name of the service to manage.
#
# @example Hiera configuration
#   warewulf::service::manage: true
#   warewulf::service::enable: true
#   warewulf::service::ensure: running
#   warewulf::service::service_name: warewulfd
#
class warewulf::service (
  Boolean $manage,
  Boolean $enable,
  String $ensure,
  String $service_name,
) {
  if $manage {
    service { $service_name:
      ensure => $ensure,
      enable => $enable,
    }
  }
}
