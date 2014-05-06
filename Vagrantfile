# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "centos-6.5-x86_64"
  config.vm.box_url = "\\software\\centos-6.5-x86_64.box"
  # config.vm.box_url = "https://dl.dropboxusercontent.com/u/9899790/centos-6.5-x86_64.box"

  config.vm.define "osb1035" , primary: true do |osb1035|
    # All Vagrant configuration is done here. The most common configuration
    # options are documented and commented below. For a complete reference,
    # please see the online documentation at vagrantup.com.

    osb1035.vm.hostname = "osb1035.local"
    # Port forwaring for OSB en Weblogic
    osb1035.vm.network "forwarded_port", guest: 7001, host: 7011
    osb1035.vm.network "forwarded_port", guest: 8001, host: 8011

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    #osb1035.vm.network "private_network", ip: "10.10.10.10"
    
    # Create a public network, which generally matched to bridged network.
    # Bridged networks make the machine appear as another physical device on
    # your network.
    osb1035.vm.network "public_network"

    # If true, then any SSH connections made will enable agent forwarding.
    # Default value: false
    # config.ssh.forward_agent = true

    # Share an additional folder to the guest VM. The first argument is
    # the path on the host to the actual folder. The second argument is
    # the path on the guest to mount the folder. And the optional third
    # argument is a set of non-required options.
    osb1035.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    osb1035.vm.synced_folder "/software", "/software", :mount_options => ["dmode=777","fmode=777"]

    osb1035.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "3196"]
      vb.customize ["modifyvm", :id, "--name", "OSB 10.3.5"]
    end
  
    osb1035.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml"
    
    osb1035.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "osb1035.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"
     
      puppet.facter = {
        "environment"                     => "development",
        "vm_type"                         => "vagrant",
        "override_weblogic_user"          => "wls",
        "override_weblogic_domain_folder" => "/opt/oracle/wlsdomains",
      }
      
    end

  end

end
