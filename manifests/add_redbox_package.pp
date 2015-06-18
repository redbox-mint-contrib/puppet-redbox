define puppet-redbox::add_redbox_package (
  $packages        = $title,
  $owner           = undef,
  $has_ssl         = undef,
  $tf_env          = undef,
  $system_config   = undef,
  $base_server_url = undef,) {
  if ($packages[server_url_context]) {
    $server_url = "${base_server_url}/${packages[server_url_context]}"
  } else {
    $server_url = $base_server_url
  }
  $redbox_package = $packages[package]
  $redbox_system = $packages[system]

  puppet_common::add_directory { $packages[install_directory]: owner => $owner, before => Package[$redbox_package] }
 if $redbox_system == 'mint' {
    # check if there are dependencies/chains
    if ($packages[pre_install]) {
      package {$packages[pre_install]:
      }
    }
    package{$redbox_package:}
    if ($packages[post_install]) {
      package {$packages[post_install]:}
    }
  } else {
    package { $redbox_package: }
  }

  if ($redbox_system == 'redbox') {
    puppet-redbox::update_system_config { [
      "${packages[install_directory]}/home/config-include/2-misc-modules/rapidaaf.json",
      "${packages[install_directory]}/home/config-include/plugins/rapidaaf.json"]:
      system_config => $system_config,
      notify        => Exec["$redbox_system-restart_on_refresh"],
      subscribe     => Package[$redbox_package],
    }
    if ($system_config[api]) {
    file_line { 'update system-config.json api key':
      path  => "${packages[install_directory]}/home/config-include/2-misc-modules/apiSecurity.json",
      line  => "\"apiKey\": \"${system_config[api][clients][apiKey]}\",",
      match => "\"apiKey\":.*$",
      subscribe     => Package[$redbox_package],
    } ->
    file_line { 'update system-config.json api user':
      path  => "${packages[install_directory]}/home/config-include/2-misc-modules/apiSecurity.json",
      line  => "\"username\": \"${system_config[api][clients][username]}\"",
      match => "\"username\":.*$",
      subscribe     => Package[$redbox_package],
    }
	}

  }

  puppet-redbox::update_server_env { "${packages[install_directory]}/server/tf_env.sh":
    tf_env     => $tf_env,
    has_ssl    => $has_ssl,
    server_url => $server_url,
    notify     => Exec["$redbox_system-restart_on_refresh"],
    subscribe  => Package[$redbox_package],
  }

  service { $redbox_system:
    enable     => true,
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    status     => "service ${redbox_system} status | grep 'is running'",
    subscribe  => Package[$redbox_package],
  }

  exec { "$redbox_system-restart_on_refresh":
    command     => "service ${redbox_system} restart",
    tries       => 2,
    try_sleep   => 3,
    refreshonly => true,
    user        => 'root',
    logoutput   => true,
  }

  #  mint is not always proxied
  if ($redbox_system == 'mint') {
    puppet-redbox::prime_system { "localhost:9001/mint": subscribe => [
        Exec["$redbox_system-restart_on_refresh"],
        Service[$redbox_system]], }
  } else {
    puppet-redbox::prime_system { $server_url: subscribe => [
        Exec["$redbox_system-restart_on_refresh"],
        Service[$redbox_system]], }
  }

  puppet-redbox::add_tidy { $redbox_system: require => Service[$redbox_system], }
}
