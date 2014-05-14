define puppet-redbox::prime_system ($system = $title,) {
  exec { "$system-primer":
    command     => "wget --wait=10 --spider -O /dev/null ${system}",
    tries       => 3,
    try_sleep   => 20,
    refreshonly => true,
    user        => 'root',
    logoutput   => true,
  }

}