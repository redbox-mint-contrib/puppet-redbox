define puppet-redbox::add_ssl_cert ($ssl_config = $title) {
  $ssl_config_parent = dirname("${ssl_config[file]}")
  ensure_resource('file', $ssl_config_parent, {
    ensure => 'directory',
  }
  )

  if ($ssl_config[mode]) {
    $mode = $ssl_config[mode]
  } else {
    $mode = 0444
  }

  if ($ssl_config[content]) {
    file { $ssl_config[file]:
      content => $ssl_config[content],
      ensure  => file,
      mode    => $mode,
      require => File[$ssl_config_parent],
    }
  } else {
    file { $ssl_config[file]:
      ensure  => file,
      mode    => $mode,
      require => File[$ssl_config_parent],
    }
  }

}
