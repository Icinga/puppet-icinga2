# == Class: icinga2::config
#
# This class exists to manage general configuration files needed by Icinga2 to run.
#
# === Parameters
#
# This class does not provide any parameters.
#
# === Examples
#
# This class is private and should not be called by others than this module.
#
# === Authors
#
# Icinga Development Team <info@icinga.com>
#
class icinga2::config {

  if $module_name != $caller_module_name {
    fail("icinga2::config is a private class of the module icinga2, you're not permitted to use it.")
  }

  $constants = prefix($::icinga2::_constants, 'const ')
  $conf_dir  = $::icinga2::params::conf_dir
  $plugins   = $::icinga2::plugins
  $confd     = $::icinga2::_confd

  if $::kernel != 'windows' {
    $template_constants  = icinga2_attributes($constants)
    $template_mainconfig = template('icinga2/icinga2.conf.erb')
  } else {
    $template_constants  = regsubst(icinga2_attributes($constants), '\n', "\r\n", 'EMG')
    $template_mainconfig = regsubst(template('icinga2/icinga2.conf.erb'), '\n', "\r\n", 'EMG')
  }

  file { "${conf_dir}/constants.conf":
    ensure  => file,
    content => $template_constants,
  }

  file { "${conf_dir}/icinga2.conf":
    ensure  => file,
    content => $template_mainconfig,
  }

}
