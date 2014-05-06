# test
#
# one machine setup with weblogic 10.3.5 
# needs jdk6, orawls, orautils, fiddyspence-sysctl, erwbgy-limits puppet modules
#

node 'osb1035.local' {
  
   include os,java, ssh, orautils 
   include wls1035
   include wls1035_domain
   include osb1035_files
   include maintenance
   include packdomain


   Class['os']  -> 
     Class['ssh']  -> 
        Class['java']  -> 
          Class['wls1035'] -> 
            Class['wls1035_domain'] -> 
              Class['packdomain'] 
#                Class['osb1035_files']
}  

# operating settings for Middleware
class os {

  notice "class os ${operatingsystem}"

  $default_params = {}
  $host_instances = hiera('hosts', [])
  create_resources('host',$host_instances, $default_params)

  # 2GB is the largest swapfle that XE allows
  exec { "create swap file":
    command => "/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=2048",
    creates => "/var/swap.1",
  }

  exec { "attach swap file":
    command => "/sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1",
    require => Exec["create swap file"],
    unless => "/sbin/swapon -s | grep /var/swap.1",
  }

  #add swap file entry to fstab
  exec {"add swapfile entry to fstab":
    command => "/bin/echo >>/etc/fstab /var/swap.1 swap swap defaults 0 0",
    require => Exec["attach swap file"],
    user => root,
    unless => "/bin/grep '^/var/swap.1' /etc/fstab 2>/dev/null",
  }

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

  group { 'dba' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  # password = oracle
  user { 'wls' :
    ensure     => present,
    groups     => 'dba',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/wls",
    comment    => 'wls user created by Puppet',
    managehome => true,
    require    => Group['dba'],
  }

  $install = [ 'binutils.x86_64','unzip.x86_64']

  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'wls'     => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
               },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}

class ssh {
  require os

  notice 'class ssh'

  file { "/home/wls/.ssh/":
    owner  => "wls",
    group  => "dba",
    mode   => "700",
    ensure => "directory",
    alias  => "wls-ssh-dir",
  }
  
  file { "/home/wls/.ssh/id_rsa.pub":
    ensure  => present,
    owner   => "wls",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["wls-ssh-dir"],
  }
  
  file { "/home/wls/.ssh/id_rsa":
    ensure  => present,
    owner   => "wls",
    group   => "dba",
    mode    => "600",
    source  => "/vagrant/ssh/id_rsa",
    require => File["wls-ssh-dir"],
  }
  
  file { "/home/wls/.ssh/authorized_keys":
    ensure  => present,
    owner   => "wls",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["wls-ssh-dir"],
  }        
}

class java {
  require os

  notice 'class java'

  $remove = [ "java-1.7.0-openjdk.x86_64", "java-1.6.0-jdk.x86_64" ]

  package { $remove:
    ensure  => absent,
  }

  include jdk6

  jdk6::install6{ 'jdk1.6.0_45':
      version              => "6u45" , 
      fullVersion          => "jdk1.6.0_45",
      alternativesPriority => 18000, 
      downloadDir          => hiera('wls_download_dir'),
      sourcePath           => hiera('wls_source'),
  }

}

class wls1035 {

   class { 'wls::urandomfix' :}

   $jdkWls11gJDK  = hiera('wls_jdk_version')
   $wls11gVersion = hiera('wls_version')
                       
   $puppetDownloadMntPoint = hiera('wls_source')                       
 
   $osOracleHome = hiera('wls_oracle_base_home_dir')
   $osMdwHome    = hiera('wls_middleware_home_dir')
   $osWlHome     = hiera('wls_weblogic_home_dir')
   $user         = hiera('wls_os_user')
   $group        = hiera('wls_os_group')
   $downloadDir  = hiera('wls_download_dir')
   $logDir       = hiera('wls_log_dir')     

  # set the defaults
  Wls::Installwls {
    version                => $wls11gVersion,
    fullJDKName            => $jdkWls11gJDK,
    oracleHome             => $osOracleHome,
    mdwHome                => $osMdwHome,
    user                   => $user,
    group                  => $group,    
    downloadDir            => $downloadDir,
    remoteFile             => hiera('wls_remote_file'),
    puppetDownloadMntPoint => $puppetDownloadMntPoint,
  }

  Wls::Nodemanager {
    wlHome       => $osWlHome,
    fullJDKName  => $jdkWls11gJDK,  
    user         => $user,
    group        => $group,
    serviceName  => $serviceName,  
    downloadDir  => $downloadDir, 
  }

  Wls::Bsupatch {
    mdwHome                => $osMdwHome,
    wlHome                 => $osWlHome,
    fullJDKName            => $jdkWls11gJDK,
    user                   => $user,
    group                  => $group,
    downloadDir            => $downloadDir, 
    puppetDownloadMntPoint => $puppetDownloadMntPoint, 
    remoteFile             => hiera('wls_remote_file'),
  }

  # install
  wls::installwls{'11gPS4':
     createUser   => false, 
  }
  
  # weblogic patch
  #wls::bsupatch{'p16088411':
  #   patchId      => 'L5TD',    
  #   patchFile    => 'p16088411_1035_Generic.zip',  
  #   require      => Wls::Installwls['11gPS4'],
  #}

  wls::installosb{'osbPS4':
    mdwHome                => $osMdwHome,
    wlHome                 => $osWlHome,
    oracleHome             => $osOracleHome,
    fullJDKName            => $jdkWls11gJDK,  
    user                   => $user,
    group                  => $group,    
    downloadDir            => $downloadDir,
    puppetDownloadMntPoint => $puppetDownloadMntPoint, 
    osbFile                => 'ofm_osb_generic_11.1.1.5.0_disk1_1of1.zip',
    remoteFile             => hiera('wls_remote_file'),
    require                => Wls::Installwls['11gPS4'],
  }

  #nodemanager configuration and starting
  wls::nodemanager{'nodemanager11g':
     listenPort    => hiera('domain_nodemanager_port'),
     listenAddress => hiera('domain_adminserver_address'),
     logDir        => $logDir,
     require       => Wls::Installwls['11gPS4'],
  }
   
  orautils::nodemanagerautostart{"autostart ${wlsDomainName}":
      version     => "1111",
      wlHome      => $osWlHome, 
      user        => $user,
      logDir      => $logDir,
      require     => Wls::Nodemanager['nodemanager11g'];
  }

}

class wls1035_domain{

  $wlsDomainName   = hiera('domain_name')
  $wlsDomainsPath  = hiera('wls_domains_path_dir')
  $osTemplate      = hiera('domain_template')

  $adminListenPort = hiera('domain_adminserver_port')
  $nodemanagerPort = hiera('domain_nodemanager_port')
  $address         = hiera('domain_adminserver_address')

  $userConfigDir   = hiera('wls_user_config_dir')
  $jdkWls11gJDK    = hiera('wls_jdk_version')
                       
  $osOracleHome = hiera('wls_oracle_base_home_dir')
  $osMdwHome    = hiera('wls_middleware_home_dir')
  $osWlHome     = hiera('wls_weblogic_home_dir')
  $user         = hiera('wls_os_user')
  $group        = hiera('wls_os_group')
  $downloadDir  = hiera('wls_download_dir')
  $logDir       = hiera('wls_log_dir') 

  # install SOA/OSB domain
  wls::wlsdomain{'Wls1035Domain':
    wlHome          => $osWlHome,
    mdwHome         => $osMdwHome,
    fullJDKName     => $jdkWls11gJDK, 
    wlsTemplate     => $osTemplate,
    domain          => $wlsDomainName,
    developmentMode => false,
    adminServerName => hiera('domain_adminserver'),
    adminListenAdr  => $address,
    adminListenPort => $adminListenPort,
    nodemanagerPort => $nodemanagerPort,
    java_arguments  => { "ADM" => "-XX:PermSize=256m -XX:MaxPermSize=512m -Xms1024m -Xmx1024m" },
    wlsUser         => hiera('wls_weblogic_user'),
    password        => hiera('domain_wls_password'),
    user            => $user,
    group           => $group,    
    logDir          => $logDir,
    downloadDir     => $downloadDir, 
    reposDbUrl      => $reposUrl,
    reposPrefix     => $reposPrefix,
    reposPassword   => $reposPassword,
  }

  # start AdminServers for configuration of WLS Domain
  wls::wlscontrol{'startAdminServer':
    wlsDomain     => $wlsDomainName,
    wlsDomainPath => "${wlsDomainsPath}/${wlsDomainName}",
    wlsServer     => "AdminServer",
    action        => 'start',
    wlHome        => $osWlHome,
    fullJDKName   => $jdkWls11gJDK,  
    wlsUser       => hiera('wls_weblogic_user'),
    password      => hiera('domain_wls_password'),
    address       => $address,
    port          => $nodemanagerPort,
    user          => $user,
    group         => $group,
    downloadDir   => $downloadDir,
    logOutput     => true, 
    require       => Wls::Wlsdomain['Wls1035Domain'],
  }

  # create keystores for automatic WLST login
  wls::storeuserconfig{'Wls1035Domain_keys':
    wlHome        => $osWlHome,
    fullJDKName   => $jdkWls11gJDK,
    domain        => $wlsDomainName, 
    address       => $address,
    wlsUser       => hiera('wls_weblogic_user'),
    password      => hiera('domain_wls_password'),
    port          => $adminListenPort,
    user          => $user,
    group         => $group,
    userConfigDir => $userConfigDir, 
    downloadDir   => $downloadDir, 
    require       => Wls::Wlscontrol['startAdminServer'],
  }

}

class osb1035_files {

  $osMdwHome  = hiera('wls_middleware_home_dir')
  $xpath_dir  = hiera('osb_xpath_dir')
  $xpath_file = hiera('osb_xpath_files1')

  $xpath_properties_file_loc = "${osMdwHome}${xpath_dir}${xpath_file}.properties"
  $xpath_xml_file_loc        = "${osMdwHome}${xpath_dir}${xpath_file}.xml"
  $xpath_jar_file_loc        = "${osMdwHome}${xpath_dir}${xpath_file}.jar"

  notice "File: ${xpath_properties_file_loc}"
  file { 'xpath-properties-file':
      path    => $xpath_properties_file_loc,
      owner   => hiera('wls_os_user'),
      group   => hiera('wls_os_group'),
      mode    => 0640,
      replace => true,
      source  => "/vagrant/software/osb/${xpath_properties_file}",      
      require => Wls::Wlsdomain['Wls1035Domain'],
  }

  notice "File: ${xpath_xml_file_loc}"
  file { 'xpath-xml-file':
      path    => $xpath_xml_file_loc,
      owner   => hiera('wls_os_user'),
      group   => hiera('wls_os_group'),
      mode    => 0640,
      replace => true,
      source  => "/vagrant/software/osb/${xpath_xml_file}",
      require => Wls::Wlsdomain['Wls1035Domain'],
  }

  notice "File: ${xpath_jar_file_loc}"
  file { 'xpath-jar-file':
      path    => $xpath_jar_file_loc,
      owner   => hiera('wls_os_user'),
      group   => hiera('wls_os_group'),
      mode    => 0640,
      replace => true,
      source  => "/vagrant/software/osb/${xpath_jar_file}",
      require => Wls::Wlsdomain['Wls1035Domain'],
  }
}

class maintenance {

  $osOracleHome = hiera('wls_oracle_base_home_dir')
  $osMdwHome    = hiera('wls_middleware_home_dir')
  $osWlHome     = hiera('wls_weblogic_home_dir')
  $user         = hiera('wls_os_user')
  $group        = hiera('wls_os_group')
  $downloadDir  = hiera('wls_download_dir')
  $logDir       = hiera('wls_log_dir')     

  $mtimeParam = "1"


  cron { 'cleanwlstmp' :
    command => "find /tmp -name '*.tmp' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/tmp_purge.log 2>&1",
    user    => $user,
    hour    => 06,
    minute  => 25,
  }

  cron { 'mdwlogs' :
    command => "find ${osMdwHome}/logs -name 'wlst_*.*' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/wlst_purge.log 2>&1",
    user    => $user,
    hour    => 06,
    minute  => 30,
  }

}


class packdomain {

  $wlsDomainName   = hiera('domain_name')
  $jdkWls11gJDK    = hiera('wls_jdk_version')
                       
  $osMdwHome       = hiera('wls_middleware_home_dir')
  $osWlHome        = hiera('wls_weblogic_home_dir')
  $user            = hiera('wls_os_user')
  $group           = hiera('wls_os_group')
  $downloadDir     = hiera('wls_download_dir')

  wls::packdomain{'packWlsDomain':
      wlHome          => $osWlHome,
      mdwHome         => $osMdwHome,
      fullJDKName     => $jdkWls11gJDK,  
      user            => $user,
      group           => $group,    
      downloadDir     => $downloadDir, 
      domain          => $wlsDomainName,
  }
}
