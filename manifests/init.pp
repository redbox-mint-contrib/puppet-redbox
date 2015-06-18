# == Class: puppet-redbox
#
# Puppet Centos installation of redbox and mint, including harvester,apache proxy and system_config
# population.
# === Authors
#
# Matt Mulholland <matt@redboxresearchdata.com.au>
# <a href="https://github.com/shilob">Shilo Banihit</a>
# === Copyright
#
# Copyright (C) 2013 Queensland Cyber Infrastructure Foundation (http://www.qcif.edu.au/)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
class puppet-redbox (
  $redbox_user              = hiera(redbox_user, 'redbox'),
  $install_parent_directory = hiera(install_parent_directory, '/opt'),
  $packages                 = hiera_hash(packages, {
    redbox             => {
      system            => 'redbox',
      package           => 'redbox-rdsi-arms-qcif',
      install_directory => '/opt/redbox',
    }
    ,
    mint               => {
      system             => 'mint',
      package            => 'mint-distro',
      server_url_context => 'mint',
      install_directory  => '/opt/mint',
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
  $exec_path                = hiera_array(exec_path, [
    '/usr/local/bin',
    '/opt/local/bin',
    '/usr/bin',
    '/usr/sbin',
    '/bin',
    '/sbin']),
  $ssl_config               = hiera_hash(ssl_config, {
    cert  => {
      file  => "/etc/ssl/local_certs/${::fqdn}.crt"
    }
    ,
    key   => {
      file => "/etc/ssl/local_certs/${::fqdn}.key",
      mode => 0444
    }
    ,
    chain => {
      file  => "/etc/ssl/local_certs/${::fqdn}.chain"
    }
  }
  ),
  $yum_repos                = hiera_array(yum_repos, [{
      name     => 'redbox',
      descr    => 'Redbox_repo',
      baseurl  => 'http://dev.redboxresearchdata.com.au/yum/releases',
      gpgcheck => 0,
      enabled  => 1
    }
    ]),
  $crontab                  = hiera_hash(crontab, undef),
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

  puppet_common::add_systemuser { $redbox_user: }

  ensure_resource(file, $install_parent_directory, {
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  )

  class { 'puppet_common::java':
  }

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

  puppet_common::add_yum_repo { $yum_repos: exec_path => $exec_path } ->
  puppet-redbox::add_redbox_package { [values($packages)]:
    owner           => $redbox_user,
    has_ssl         => $has_ssl,
    tf_env          => $tf_env,
    system_config   => $system_config,
    base_server_url => $server_url,
    require         => [Puppet_common::Add_systemuser[$redbox_user], Class['Puppet_common::Java']]
  }

  if ($crontab) {
    puppet_common::add_cron { $crontab: cron_path => join($exec_path, ":"), }
  }

  tidy { '/var/lib/puppet/reports':
    age     => '1w',
    recurse => true,
    matches => ["*.yaml"],
  }
}
