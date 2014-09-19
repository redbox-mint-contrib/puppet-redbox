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
# <a href="https://github.com/shilob">Shilo Banihit</a>
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class puppet-redbox (
  $redbox_user              = hiera(redbox_user, 'redbox'),
  $directories              = hiera_array(directories, ['redbox', 'mint']),
  $install_parent_directory = hiera(install_parent_directory, '/opt'),
  $packages                 = hiera_hash(packages, {
    redbox             => {
      system             => 'redbox',
      package            => 'redbox-rdsi-arms-qcif',
      server_url_context => '',
    }
    ,
    mint               => {
      system             => 'mint',
      package            => 'mint-distro',
      server_url_context => 'mint',
    }
  }
  ),
  $proxy                    = hiera_array(proxy, [
    {
      path => '/mint',
      url  => 'http://localhost:9001/mint'
    }
    ,
    {
      path => '/redbox',
      url  => 'http://localhost:9000/redbox'
    }
    ]),
  $has_dns                  = hiera(has_dns, false),
  $has_ssl                  = hiera(has_ssl, false),
  $exec_path                = hiera(exec_path, [
    '/usr/local/bin',
    '/opt/local/bin',
    '/usr/bin',
    '/usr/sbin',
    '/bin',
    '/sbin']),
  $ssl_config               = hiera_hash(ssl_config, {
    cert  => {
      file  => "/etc/ssl/local_certs/SSLCertificateFile/${::fqdn}.crt"
    }
    ,
    key   => {
      file => "/etc/ssl/local_certs/SSLCertificateKeyFile/${::fqdn}.key",
      mode => 0444
    }
    ,
    chain => {
      file  => "/etc/ssl/local_certs/SSLCertificateChainFile/${::fqdn}.chain"
    }
  }
  ),
  $yum_repos                = hiera_array(yum_repos, [{
      name     => 'redbox',
      descr    => 'Redbox_repo',
      baseurl  => 'http://dev.redboxresearchdata.com.au/yum/snapshots',
      gpgcheck => 0,
      enabled  => 1
    }
    ]),
  $crontab                  = hiera_array(crontab, undef),
  $tf_env                   = hiera_hash(tf_env, undef),
  $system_config            = hiera_hash(system_config, undef)) {
  if ($has_dns and $::fqdn) {
    $server_url = $::fqdn
  } elsif ($::ipaddress) {
    $server_url = $::ipaddress
  } else {
    $server_url = $::ipaddress_lo
  }

  Exec {
    path      => $exec_path,
    logoutput => false,
  }

  Package {
    allow_virtual => false, }

  puppet_common::add_systemuser { $redbox_user: } ->
  puppet_common::add_directory { $directories:
    owner            => $redbox_user,
    parent_directory => $install_parent_directory
  } ->
  class { 'puppet_common::java': }

  if ($proxy) {
    class { 'puppet-redbox::add_proxy_server':
      require    => Class['Puppet_common::Java'],
      before     => [Puppet-redbox::Add_redbox_package[values($packages)]],
      server_url => $server_url,
      has_ssl    => $has_ssl,
      ssl_config => $ssl_config,
      proxy      => $proxy,
    } ~> Service['httpd']

    Puppet-redbox::Add_redbox_package[values($packages)] ~> Service['httpd']

  }

  puppet-redbox::add_yum_repo { $yum_repos: } ->
  puppet-redbox::add_redbox_package { [values($packages)]:
    owner                    => $redbox_user,
    install_parent_directory => $install_parent_directory,
    has_ssl                  => $has_ssl,
    tf_env                   => $tf_env,
    system_config            => $system_config,
    base_server_url          => $server_url,
  }

  if ($crontab) {
    puppet-redbox::add_cron { $crontab: }
  }
}