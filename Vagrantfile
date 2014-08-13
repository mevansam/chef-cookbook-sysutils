# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.5.0"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  config.vm.hostname = "sysutils-berkshelf"

  # Configure proxy
  config.proxy.http     = "http://http.proxy.fmr.com:8000"
  config.proxy.https    = "http://http.proxy.fmr.com:8000"
  config.proxy.no_proxy = "localhost,127.0.0.1,*.fmr.com"

  # Set the version of chef to install using the vagrant-omnibus plugin
  config.omnibus.chef_version = :latest

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "opscode_ubuntu-12.04_chef-provisionerless"
  
  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box"
  
  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  config.vm.network :private_network, type: "dhcp"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
  #   vb.customize ["modifyvm", :id, "--memory", "1024"]
  # end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # The path to the Berksfile to use with Vagrant Berkshelf
  # config.berkshelf.berksfile_path = "./Berksfile"

  # Enabling the Berkshelf plugin. To enable this globally, add this configuration
  # option to your ~/.vagrant.d/Vagrantfile file
  config.berkshelf.enabled = true

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to exclusively install and copy to Vagrant's shelf.
  # config.berkshelf.only = []

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []

  config.vm.provision :chef_client do |chef|

    chef.arguments = "-l debug"
    chef.chef_server_url = "https://c2c-oschef-mmk1.fmr.com"
    chef.validation_key_path = "../../../.chef/chef-validator.pem"
    chef.validation_client_name = "chef-validator"
    chef.node_name = "a292082_sysutils_dev"

    chef.json = {
      env: {
        http_proxy: "http://http.proxy.fmr.com:8000",
        sysctl_add: [ ], 
        sysctl_remove: [ ],
        ulimit_add: [ ],
        ulimit_remove: [ ],
        package_repos: {
          rhel: [ ],
          debian: [ 
            [ 
              "openstack", 
              "http://ubuntu-cloud.archive.canonical.com/ubuntu", 
              "precise-updates/havana", 
              "main", 
              "keyserver.ubuntu.com", 
              "C2518248EEA14886"
            ],
            [ 
              "java", 
              "http://ppa.launchpad.net/webupd8team/java/ubuntu" 
            ]
          ] 
        },
        packages: {
          rhel: [ ],
          debian: [ 
            "python-mysqldb", 
            "keystone",
            [
              "
                echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections; 
                echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
              ",
              "oracle-java7-installer"
            ]
          ]
        },
        groups: [
          "sysutils"
        ],
        users: [ 
          [ "test", "/test", nil, true ]
        ],
        encryption_key: "1234"
      }
    }

    chef.run_list = [
        "recipe[sysutils::default]"
    ]
  end
end
