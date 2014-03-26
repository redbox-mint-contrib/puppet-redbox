class redbox::proxy_server (
  $priority   = '10',
  $server_url = $::fqdn,
  $docroot    = '/var/www/html',
  $proxy      = undef,
  $ssl_files  = undef,
  $has_ssl    = false,) {
  case $operatingsystem {
    'centos', 'redhat', 'fedora' : {
      $conf_dir    = '/etc/httpd/conf.d'
      $log_dir     = '/etc/httpd/logs'
      $apache_conf = '/etc/httpd/conf/httpd.conf'
    }
    'default'                    : {
      $conf_dir    = '/etc/apache2/sites-enabled'
      $log_dir     = '/var/log/apache2'
      $apache_conf = '/etc/apache2/apache2.conf'
    }
  }

  class { 'apache':
    default_mods        => false,
    default_confd_files => false,
    default_vhost       => false,
    servername          => $server_url,
  } ->
  # # disabling defaults in apache causes Listen 80 to be commented out - uncomment.
  file_line { 'listen_80':
    path  => "$apache_conf",
    line  => "Listen 80",
    match => ".*Listen[[:space:]]+80[[:space:]]*?$",
  }

  include apache::mod::proxy
  include apache::mod::proxy_http

  file { 'redbox.conf':
    path    => "${conf_dir}/${priority}-redbox.conf",
    ensure  => file,
    content => template("redbox/redbox.conf.erb"),
    require => Class['apache'],
  }

  if ($has_ssl and $ssl_files) {
    $conf_file_name = "redbox-ssl"
    file { [values($ssl_files)]: ensure => file, } ->
    apache::vhost { $conf_file_name:
      port       => '443',
      docroot    => $docroot,
      ssl        => $has_ssl,
      ssl_cert   => "${ssl_files[cert]}",
      ssl_key    => "${ssl_files[key]}",
      ssl_chain  => "${ssl_files[chain]}",
      proxy_pass => $proxy,
      servername => $server_url,
      priority   => $priority,
    } ->
    file_line { 'preserve_proxy_host':
      path  => "$conf_dir/${priority}-${conf_file_name}.conf",
      line  => "ProxyPreserveHost On",
      match => "^.*ProxyPreserveHost[[:space:]]+..[[:space:]]*$",
    } ->
    file_line { 'ssl_proxy_engine':
      path  => "$conf_dir/${priority}-${conf_file_name}.conf",
      line  => "SSLProxyEngine On",
      match => "^.*SSLProxyEngine[[:space:]]+..[[:space:]]*$",
    }
  }
}
