define puppet-redbox::update_system_config (
  $system_config_path = $title,
  $system_config      = undef,
  $root_path          = get_module_path('puppet-redbox')) {
  exec { "if_exists ${system_config_path}":
    command => '/bin/true',
    onlyif  => "/usr/bin/test -e ${system_config_path}",
  }

  if ($system_config) {
    $load_path = "${root_path}/lib/augeas/lenses"

    ensure_packages('augeas')

    if ($system_config[rapidAafSso]) {
      augeas { "${system_config_path}_rapid":
        load_path => $load_path,
        incl      => $system_config_path,
        lens      => 'Custom_json.lns',
        changes   => [
          "set dict/entry[. = 'rapidAafSso']/dict/entry[. = 'iss']/string \"${system_config[
              rapidAafSso][iss]}\"",
          "set dict/entry[. = 'rapidAafSso']/dict/entry[. = 'url']/string \"${system_config[
              rapidAafSso][url]}\"",
          "set dict/entry[. = 'rapidAafSso']/dict/entry[. = 'sharedKey']/string \"${system_config[
              rapidAafSso][sharedKey]}\""],
        require   => [Package['augeas'], Exec["if_exists ${system_config_path}"]],
      }
    }
  }
}
