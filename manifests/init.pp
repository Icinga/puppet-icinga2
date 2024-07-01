# @summary
#   This module installs and configures Icinga 2.
#
# @example Declare icinga2 with all defaults. Keep in mind that your operating system may not have Icinga 2 in its package repository.
#
#   include icinga2
#
# @example If you want to use the module icinga/puppet-icinga, e.g. to use the official Icinga Project repositories, enable the manage_repos parameter.
#   class { 'icinga2':
#     manage_repos => true,
#   }
#
# @example If you don't want to manage the Icinga 2 service with puppet, you can dissable this behaviour with the manage_service parameter. When set to false no service refreshes will be triggered.
#   class { 'icinga2':
#     manage_service => false,
#   }
#
# @example To manage the version of Icinga 2 binaries you can do it by disable package management:
#   package { 'icinga2':
#     ensure  => latest,
#     notifiy => Class['icinga2'],
#   }
#
#   class { 'icinga2':
#     manage_packages => false,
#   }
#
# @note Setting manage_packages to false means that all package aren't handeld by the module included the IDO packages.
#
# @example To set constants in etc/icinga2/constants.conf use the constants parameter and as value a hash, every key will be set as constant and assigned by it's value. Defaults can be overwritten.
#   class { 'icinga2':
#     ...
#     constants   => {
#       'key1'             => 'value1',
#       'key2'             => 'value2',
#       'PluginContirbDir' => '/usr/local/nagios/plugins',
#     }
#   }
#
# @example Enabling features with there defaults or loading parameters via Hiera:
#   class { 'icinga2':
#     manage_repos => true,
#     features     => ['checker', 'mainlog', 'command'],
#   }
#
# @example The ITL contains several CheckCommand definitions to load, set these in the array of the plugins parameter, i.e. for a master or satellite do the following and disbale the load of the configuration in conf.d.
#   class { 'icinga':
#     ...
#     plugins => [ 'plugins', 'contrib-plugins', 'nscp', 'windows-plugins' ],
#     confd   => false,
#   }
#
# @example Sometimes it's necessary to cover very special configurations that you cannot handle with this module. In this case you can use the icinga2::config::file tag on your file resource. This module collects all file resource types with this tag and triggers a reload of Icinga 2 on a file change.
#   include ::icinga2
#
#   file { '/etc/icinga2/conf.d/foo.conf':
#     ensure => file,
#     owner  => icinga,
#     ...
#     tag    => 'icinga2::config::file',
#     ...
#   }
#
# @example To use a different directory for your configuration, create the directory as file resource with tag icinga2::config::file.
#    file { '/etc/icinga2/local.d':
#      ensure => directory,
#      tag    => 'icinga2::config::file'
#    }
#    class { 'icinga2':
#      ...
#      confd => 'local.d',
#    }
#
# @param ensure
#   Manages if the service should be stopped or running.
#
# @param enable
#   If set to true the Icinga 2 service will start on boot.
#
# @param manage_repos
#   When set to true this module will use the module icinga/puppet-icinga to manage repositories,
#   e.g. the release repo on packages.icinga.com repository by default, the EPEL repository or Backports.
#   For more information, see http://github.com/icinga/puppet-icinga.
#
# @param manage_packages
#   If set to false packages aren't managed.
#
# @param manage_selinux
#   If set to true the icinga selinux package is installed if selinux is enabled. Also requires a
#   `selinux_package_name` (icinga2::globals) and `manage_packages` has to be set to true.
#
# @param manage_service
#   If set to true the service is managed otherwise the service also
#   isn't restarted if a config file changed.
#
# @param features
#   List of features to activate. Defaults to [checker, mainlog, notification].
#
# @param purge_features
#   Define if configuration files for features not managed by Puppet should be purged.
#
# @param constants
#   Hash of constants. Defaults are set in the params class. Your settings will be merged with the defaults.
#
# @param plugins
#   A list of the ITL plugins to load. Defaults to [ 'plugins', 'plugins-contrib', 'windows-plugins', 'nscp' ].
#
# @param confd
#   `conf.d` is the directory where Icinga 2 stores its object configuration by default. To disable it,
#   set this parameter to `false`. By default this parameter is `true`. It's also possible to assign your
#   own directory. This directory must be managed outside of this module as file resource
#   with tag icinga2::config::file.
#
class icinga2 (
  Array                      $features,
  Array                      $plugins,
  Stdlib::Ensure::Service    $ensure          = running,
  Boolean                    $enable          = true,
  Boolean                    $manage_repos    = false,
  Boolean                    $manage_packages = true,
  Boolean                    $manage_selinux  = true,
  Boolean                    $manage_service  = true,
  Boolean                    $purge_features  = true,
  Hash                       $constants       = {},
  Variant[Boolean, String]   $confd           = true,
) {
  require icinga2::globals

  # load reserved words
  $_reserved = $icinga2::globals::reserved

  # merge constants with defaults
  $_constants = $icinga2::globals::constants + $constants

  # validate confd, boolean or string
  if $confd =~ Boolean {
    if $confd { $_confd = 'conf.d' } else { $_confd = undef }
  } else {
    $_confd = $confd
  }

  Class['icinga2::config']
  -> Concat <| tag == 'icinga2::config::file' |>
  ~> Class['icinga2::service']

  if $manage_repos {
    require icinga::repos
  }

  class { 'icinga2::install': }
  -> File <| ensure == 'directory' and tag == 'icinga2::config::file' |>
  -> class { 'icinga2::config': notify => Class['icinga2::service'] }
  -> File <| ensure != 'directory' and tag == 'icinga2::config::file' |>
  ~> class { 'icinga2::service': }
  contain icinga2::install
  contain icinga2::config
  contain icinga2::service

  include prefix($features, 'icinga2::feature::')
}
