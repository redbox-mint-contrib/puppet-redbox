# == Class: puppet-redbox
#
# Full description of class puppet-redbox here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { puppet-redbox:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Matt Mulholland <matt@redboxresearchdata.com.au>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class puppet-redbox (
  $redbox_user              = hiera(redbox_user),
  $directories              = hiera_array(directories),
  $install_parent_directory = hiera(install_parent_directory),
  $deploy_parent_directory  = hiera(deploy_parent_directory),
  $packages                 = hiera_array(packages),
  $archives                 = hiera_array(archives),
  $proxy                    = hiera_array(proxy),
  $has_dns                  = hiera(has_dns),
  $has_ssl                  = hiera(has_ssl),
  $ssl_files                = hiera(ssl_files),
  $exec_path                = hiera(exec_path),
  $yum_repos                = hiera_array(yum_repos),
  $crontab                  = hiera_array(crontab),) {
  if ($has_dns and $::fqdn) {
    $server_url = $::fqdn
  } elsif ($::ipaddress) {
    $server_url = $::ipaddress
  } else {
    $server_url = $::ipaddress_lo
  }

  host { [
    $::fqdn,
    $::hostname]:
    ip => $::ipaddress,
  }

  Exec {
    path      => $exec_path,
    logoutput => false,
  }

  puppet-redbox::add_systemuser { $redbox_user: } ->
  add_directory { $directories:
    owner            => $redbox_user,
    parent_directory => $install_parent_directory,
  } ->
  class { 'puppet-redbox::java': }

  if ($proxy) {
    class { 'puppet-redbox::add_proxy_server':
      require    => Class['Puppet-redbox::Java'],
      before     => [
        Puppet-redbox::Add_redbox_package[$packages],
        Class['Puppet-redbox::deploy_script']],
      server_url => $server_url,
      has_ssl    => $has_ssl,
      ssl_files  => $ssl_files,
      proxy      => $proxy,
    } ~> Service['httpd']
  }

  class { 'puppet-redbox::deploy_script':
    archives                 => $archives,
    has_ssl                  => $has_ssl,
    server_url               => $server_url,
    install_parent_directory => $install_parent_directory,
    deploy_parent_directory  => $deploy_parent_directory,
    owner                    => $redbox_user,
  } ->
  puppet-redbox::add_yum_repo { $yum_repos: } ->
  puppet-redbox::add_redbox_package { $packages:
    owner                    => $redbox_user,
    install_parent_directory => $install_parent_directory,
    has_ssl                  => $has_ssl,
    server_url               => $server_url,
  } ->
  puppet-redbox::add_cron { $crontab: }
}