# @summary
#   Manage the Warewulf provisioning system.
#
# The `warewulf` class is the primary entry point for this module. It
# orchestrates the installation, configuration, and service management
# of Warewulf by including and ordering the internal classes:
# `warewulf::install`, `warewulf::config`, and `warewulf::service`.
#
# The class itself does not manage resources directly; instead, it
# delegates all functionality to its component classes and ensures
# they are applied in the correct order.
#
# @param manage_tftp_server [Boolean]
#   Specifies whether the TFTP server should be managed by this module.
#
# @example Basic usage
#   include warewulf
#
# @example With parameters
#   class { 'warewulf':
#     manage_tftp_server => true,
#   }
#
class warewulf (
  Boolean $manage_tftp_server,
) {
  include warewulf::install
  include warewulf::config
  include warewulf::service

  Class['warewulf::install']
  -> Class['warewulf::config']
  -> Class['warewulf::service']
}
