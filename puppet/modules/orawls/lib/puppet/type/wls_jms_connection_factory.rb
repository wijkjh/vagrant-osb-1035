require 'easy_type'
require 'utils/wls_access'
require 'utils/settings'
require 'facter'

module Puppet
  #
  newtype(:wls_jms_connection_factory) do
    include EasyType
    include Utils::WlsAccess

    desc "This resource allows you to manage a CF in a JMS Module of an WebLogic domain."

    ensurable

    set_command(:wlst)
  
    to_get_raw_resources do
      Puppet.info "index #{name}"
      wlst template('puppet:///modules/orawls/providers/wls_jms_connection_factory/index.py.erb', binding)
    end

    on_create do
      Puppet.info "create #{name} "
      template('puppet:///modules/orawls/providers/wls_jms_connection_factory/create.py.erb', binding)
    end

    on_modify do
      Puppet.info "modify #{name} "
      template('puppet:///modules/orawls/providers/wls_jms_connection_factory/modify.py.erb', binding)
    end

    on_destroy do
      Puppet.info "destroy #{name} "
      template('puppet:///modules/orawls/providers/wls_jms_connection_factory/destroy.py.erb', binding)
    end

    def self.title_patterns
      identity = lambda {|x| x}
      [
        [
          /^(.*):(.*)$/,
          [
            [ :jmsmodule, identity ],
            [ :name     , identity ]
          ]
        ]
      ]
    end

    parameter :name
    parameter :jmsmodule
    property  :jndiname
    property  :subdeployment
    property  :defaulttargeting
    property  :transactiontimeout
    property  :xaenabled

  private 

    def name
       self[:name]
    end

    def jmsmodule
       self[:jmsmodule]
    end

    def transactiontimeout
       self[:transactiontimeout]
    end

    def xaenabled
       self[:xaenabled]
    end


    def jndiname
       self[:jndiname]
    end

    def subdeployment
       self[:subdeployment]
    end

    def defaulttargeting
       self[:defaulttargeting]
    end


  end
end
