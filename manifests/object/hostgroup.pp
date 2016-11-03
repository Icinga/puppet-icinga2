# == Define: icinga2::object::hostgroup
#
# Manage Icinga2 hostgroup objects.
#
# === Parameters
#
# [*ensure*]
#   Set to present enables the endpoint object, absent disabled it. Defaults to present.
#
######## ATTRIBUTES
######## END ATTRIBUTES
#
# [*template*]
#   Set to true creates a template instead of an object. Defaults to false.
#
# [*import*]
#   Sorted List of templates to include. Defaults to an empty list.
#
# [*target*]
#   Destination config file to store in this object. File will be declared the
#   first time.
#
# [*order*]
#   String to set the position in the target file, sorted alpha numeric. Defaults to 10.
#
# === Authors
#
# Alessandro Lorenzi <alessandro@lm-net.it>
#
define icinga2::object::hostgroup (
  $ensure = 'present',
  $display_name = $title,
  $groups       = [],
  $import       = [],
  $template     = false,
  $target       = undef,
  $order        = '10',
){
  include ::icinga2::params

  $conf_dir = $::icinga2::params::conf_dir
  if $target {
    $_target = $target
  } else {
    $_target = "${conf_dir}/repository.d/hostgroups.conf"
  }

  # validation
  validate_array($import)
  validate_bool($template)
  validate_absolute_path($_target)
  validate_string($order)

  if $display_name { validate_string ($display_name) }
  if $groups { validate_array ($groups) }

  # compose attributes
  $attrs = {
    'display_name'  => $display_name,
    'groups'        => $groups,
  }

  # create object
  icinga2::object { "icinga2::object::HostGroup::${title}":
    ensure      => $ensure,
    object_name => $name,
    object_type => 'HostGroup',
    import      => $import,
    template    => $template,
    attrs       => $attrs,
    target      => $_target,
    order       => $order,
    notify      => Class['::icinga2::service'],
  }

}
