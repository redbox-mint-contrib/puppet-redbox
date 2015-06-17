define puppet-redbox::backup_previous_install (
  $system            = $title,
  $install_directory = undef,
  $backup_directory  = '/opt/backup_pre_puppet_install',) {
  puppet_common::add_directory { "${system}_backup": parent_directory => ${backup_directory}, } ->
  exec { "backup ${install_directory}":
    command   => "service ${system} stop && rsync -avz --include 'home,portal,storage,solr,server/lib,server/plugins' --exclude 'home/logs/*' ${install_directory}/${backup_directory}/${system}/\$(date '+%Y%m%d%H%M%S')/",
    tries     => 3,
    timeout   => 5,
    onlyif    => ["ls ${install_directory}/home; echo $?"],
    logoutput => true,
    cwd       => "${backup_directory}/${system}",
  }
}
