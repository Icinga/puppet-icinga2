# == Class: icinga2::feature::opentsdb
#
# This module configures the Icinga2 feature opentsdb.
#
# === Parameters
#
# [*ensure*]
#   Set to present enables the feature opentsdb, absent disables it. Defaults to present.
#
# [*host*]
#   OpenTSDB host address. Defaults to '127.0.0.1'.
#
# [*port*]
#   OpenTSDB port. Defaults to 4242.
#
# === Authors
#
# Icinga Development Team <info@icinga.com>
#
class icinga2::feature::opentsdb(
  $ensure               = present,
  $host                 = '127.0.0.1',
  $port                 = '4242',
) {

  include ::icinga2::params

  $conf_dir = $::icinga2::params::conf_dir

  # validation
  validate_re($ensure, [ '^present$', '^absent$' ],
    "${ensure} isn't supported. Valid values are 'present' and 'absent'.")
  validate_ip_address($host)
  validate_integer($port)

  # compose attributes
  $attrs = {
    host => $host,
    port => $port,
  }

  # create object
  icinga2::object { "icinga2::object::OpenTsdbWriter::opentsdb":
    object_name => 'opentsdb',
    object_type => 'OpenTsdbWriter',
    attrs       => $attrs,
    target      => "${conf_dir}/features-available/opentsdb.conf",
    order       => '10',
    notify      => $ensure ? {
      'present' => Class['::icinga2::service'],
      default   => undef,
    },
  }

  # import library 'perfdata'
  concat::fragment { 'icinga2::feature::opentsdb':
    target  => "${conf_dir}/features-available/opentsdb.conf",
    content => "library \"perfdata\"\n\n",
    order   => '05',
  }

  # manage feature
  icinga2::feature { 'opentsdb':
    ensure => $ensure,
  }
}
