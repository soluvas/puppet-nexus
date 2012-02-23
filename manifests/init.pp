# Class: nexus
#
# This module manages nexus
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class nexus (
  $version = '2.0',
  $mirror_url = 'http://nexus.com/'
) {
  $download_file = "nexus-${version}.war"
  $download_url = "${mirror_url}${download_file}"
  $dir = "${tomcat::webapps_dir}/nexus"
  $work_dir = '/home/nexus'
  
  # Create "home folder" aka sonatype-work/nexus
  file { $work_dir:
    ensure => directory,
    owner => $tomcat::user, group => $tomcat::group,
    mode => 0775,
    require => [ Class['tomcat'] ]
  }

  exec { nexus_download:
    command => "curl -v --progress-bar -o '/var/tmp/${download_file}' '$download_url'",
    creates => "/var/tmp/${download_file}",
    path => ["/bin", "/usr/bin"],
    logoutput => true,
    user => $tomcat::user, group => $tomcat::group,
    require => [ Class['tomcat'], Package['curl'] ],
    unless => "/usr/bin/test -d '${dir}'"
  }
  file { '/var/tmp/nexus':
  	ensure => directory,
  	owner => $tomcat::user, group => $tomcat::group,
    require => Class['tomcat'],
    unless => "/usr/bin/test -d '${dir}'"
  }
  exec { nexus_extract:
    command => "tar -xzf /var/tmp/${download_file} -C /var/tmp/nexus",
    creates => "/var/tmp/nexus/WEB-INF",
    path => ["/bin", "/usr/bin"],
    user => $tomcat::user, group => $tomcat::group,
    require => [ Exec['nexus_download'], File['/var/tmp/nexus'] ],
    unless => "/usr/bin/test -d '${dir}'"
  }
  file { '/var/tmp/nexus/WEB-INF/plexus.properties':
  	content => template('nexus/plexus.properties.erb'),
    owner => $tomcat::user, group => $tomcat::group,
    mode => 0664,
    require => [ Class['tomcat'], Exec['nexus_extract'] ],
    unless => "/usr/bin/test -d '${dir}'"
  }
  exec { nexus_move:
    command => "mv -v '/var/tmp/nexus' '${dir}'",
    creates => $dir,
    logoutput => true,
    path => ["/bin", "/usr/bin"],
    user => $tomcat::user, group => $tomcat::group,
    require => File['/var/tmp/nexus/WEB-INF/plexus.properties'],
    unless => "/usr/bin/test -d '${dir}'"
  }

}
