define puppet-redbox::add_ssl_cert ($ssl_config = $title) {
  create_parent_directories("${ssl_config[file]}")

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
    }
  } else {
    file { $ssl_config[file]:
      ensure => file,
      mode   => $mode,
    }
  }

}