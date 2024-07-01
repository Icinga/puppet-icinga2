# @summary
#   This class handles the installation of the Icinga 2 package.
#   On Windows only chocolatey is supported as installation source.
#
# @api private
#
class icinga2::install {
  assert_private()

  $package_name         = $icinga2::globals::package_name
  $manage_packages      = $icinga2::manage_packages
  $manage_selinux       = $icinga2::manage_selinux
  $selinux_package_name = $icinga2::globals::selinux_package_name
  $cert_dir             = $icinga2::globals::cert_dir
  $conf_dir             = $icinga2::globals::conf_dir
  $user                 = $icinga2::globals::user
  $group                = $icinga2::globals::group

  if $manage_packages {
    if $facts['os']['family'] == 'windows' { Package { provider => chocolatey, } }

    package { $package_name:
      ensure => installed,
      before => File[$cert_dir, $conf_dir],
    }

    if $manage_selinux and fact('os.selinux.enabled') and $facts['os']['selinux']['enabled'] and $selinux_package_name {
      package { $selinux_package_name:
        ensure  => installed,
        require => Package[$package_name],
      }
    }
  }

  file {
    default:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0750',
      ;
    $conf_dir:
      seltype => 'icinga2_etc_t',
      ;
    $cert_dir:
      seltype => 'icinga2_var_lib_t',
      ;
  }
}
