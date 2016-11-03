# == Define: icinga2::object::notification
#
# Manage Icinga2 notification objects.
#
# === Parameters
#
# [*ensure*]
#   Set to present enables the endpoint object, absent disabled it. Defaults to present.
#
# [*host_name*]
# 	The name of the host this notification belongs to.
#
# [*service_name*]
# 	The short name of the service this notification belongs to. If omitted, this
#   notification object is treated as host notification.
#
# [*vars*]
# 	A dictionary containing custom attributes that are specific to this
#   notification object.
#
# [*users*]
# 	A list of user names who should be notified.
#
# [*user_groups*]
# 	A list of user group names who should be notified.
#
# [*times*]
# 	A dictionary containing begin and end attributes for the notification.
#
# [*command*]
# 	The name of the notification command which should be executed when the
#   notification is triggered.
#
# [*interval*]
# 	The notification interval (in seconds). This interval is used for active
#   notifications. Defaults to 30 minutes. If set to 0, re-notifications are
#   disabled.
#
# [*period*]
# 	The name of a time period which determines when this notification should be
#   triggered. Not set by default.
#
# [*zone*]
# 	The zone this object is a member of.
#
# [*types*]
# 	A list of type filters when this notification should be triggered. By
#   default everything is matched.
#
# [*states*]
# 	A list of state filters when this notification should be triggered. By
#   default everything is matched.
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
define icinga2::object::notification (
  $ensure       = 'present',
  $host_name    = undef,
  $service_name = undef,
  $vars         = undef,
  $users        = undef,
  $user_groups  = undef,
  $times        = undef,
  $command      = undef,
  $interval     = undef,
  $period       = undef,
  $zone         = undef,
  $types        = undef,
  $states       = undef,
  $apply        = false,
  $assign       = [],
  $ignore       = [],
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
    $_target = "${conf_dir}/conf.d/notifications.conf"
  }

  # validation
  validate_array($import)
  validate_bool($template)
  validate_absolute_path($_target)
  validate_string($order)

  validate_string ($host_name)
  if $service_name { validate_string ($service_name)}
  if $vars { validate_hash ($vars )}
  if $users { validate_array ($users )}
  if $user_groups { validate_array ($user_groups )}
  if $times { validate_hash ($times )}
  if $command { validate_string ($command )}
  if $interval { validate_integer ($interval )}
  if $period { validate_string ($period )}
  if $zone { validate_string ($zone) }
  if $types { validate_array ($types) }
  if $states { validate_array ($states) }
  if $assign { validate_array ($assign) }
  if $ignore { validate_array ($ignore) }

  # compose attributes
  $attrs = {
    'host_name' => $host_name,
    'service_name' => $service_name,
    'vars' => $vars,
    'users' => $users,
    'user_groups' => $user_groups,
    'times' => $times,
    'command' => $command,
    'interval' => $interval,
    'period' => $period,
    'zone' => $zone,
    'types' => $types,
    'states' => $states,
  }

  # create object
  icinga2::object { "icinga2::object::Notification::${title}":
    ensure      => $ensure,
    object_name => $name,
    object_type => 'Notification',
    import      => $import,
    template    => $template,
    attrs       => $attrs,
    target      => $_target,
    order       => $order,
    apply       => $apply,
    assign      => $assign,
    ignore      => $ignore,
    notify      => Class['::icinga2::service'],
  }

}
