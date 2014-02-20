class resourcemap(
  $deploy_user = undef,
  $host_name = $fqdn
) {

  class { 'mysql::server': }

  class { 'elasticsearch':
    repo_version => '0.90',
    manage_repo => true,
    java_install => true,
  }

  $database_password = 'resourcemap'

  mysql::db { 'resourcemap':
    user => 'resourcemap',
    password => $database_password,
    host => 'localhost',
    grant => ['ALL'],
  }

  class { 'rbenv': }
  rbenv::plugin { 'sstephenson/ruby-build': }
  rbenv::build { '1.9.3-p484': }

  class { 'apache': }

  class { 'rbenv_passenger':
    ruby_version => '1.9.3-p484'
  }

  $appdir = '/u/apps/resource_map'

  ensure_resource('file', '/u', {ensure => directory})
  ensure_resource('file', '/u/apps', {ensure => directory})

  file { [$appdir, "$appdir/shared", "$appdir/shared/log", "$appdir/releases"]:
    ensure => directory,
    owner => $deploy_user
  }

  file { "$appdir/current/public": }

  file { "$appdir/shared/database.yml":
    ensure => present,
    content => template('resourcemap/database.yml.erb')
  }

  file { "$appdir/shared/nuntium.yml":
    ensure => present,
    content => template('resourcemap/nuntium.yml.erb')
  }

  file { "$appdir/shared/settings.yml":
    ensure => present,
    content => template('resourcemap/settings.yml.erb')
  }

  ensure_packages ["mercurial", "libxml2-dev", "libxslt1-dev", "nodejs", "redis-server", "postfix"]

  apache::vhost { 'resourcemap':
    port => '80',
    servername => $host_name,
    docroot => "$appdir/current/public"
  }
}
