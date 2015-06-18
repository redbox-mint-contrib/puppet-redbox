define puppet-redbox::add_tidy ($system = $title,) {
  tidy { "/opt/${system}/home/logs":
    age     => "1m",
    recurse => true,
    matches => ["*.log"],
    size    => "100m",
    backup  => true,
  }

}
