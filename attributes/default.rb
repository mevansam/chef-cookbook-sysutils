# Default attributes for sysutils cookbook

default["env"]["secret_file_path"] = nil

# Array of network interfaces. Each interface hash must map to an attribute
# of the network_interface resource of the network_interface cookbook.
# https://github.com/redguide/network_interfaces/blob/master/resources/default.rb
#
# example:
#
#   * note: Each network interface is represented as a hash of key-value pairs 
#           which will be mapped to attributes of the network_interfaces resource.
#
#   "network_interfaces" => [
#       {          
#          device => ...
#          .
#          .
#       }
#   ]
#
# Currently this applies only for Ubuntu/Debian systems only
#
default["env"]["network_interfaces"] = [ ]

default["env"]["http_proxy"] = nil
default["env"]["https_proxy"] = nil
default["env"]["ftp_proxy"] = nil
default["env"]["no_proxy"] = nil

# Additional block storage to allocate as a data disk
default["env"]["data_disk"] = nil
default["env"]["data_path"] = nil

default["env"]["sysctl_add"] = [ ]
default["env"]["sysctl_remove"] = [ ]

default["env"]["ulimit_add"] = [ ]
default["env"]["ulimit_remove"] = [ ]

# Enable/Disable local firewall
default["env"]["firewall"] = true

# Each repo should be an array of [ name uri, distribution, components, keyserver, key ]
# Only the name and uri are required and all the other values are optional
default["env"]["package_repos"]["rhel"] = [ ]
default["env"]["package_repos"]["debian"] = [ ]

# Indicates if package cache needs to be updated
default["env"]["package_repos"]["cache_updated"] = false

# Each package is either a string or an array of [ cmd, package ] where
# cmd is a list of commands to execute in the shell such as debconf
# selections.
default["env"]["packages"]["rhel"] = [ ]
default["env"]["packages"]["debian"] = [ ]

# Add user groups
default["env"]["groups"] = [ ]

# Add users - array of 
#
# - [ user_name, home_dir, group_name_or_id, is_passwordless_sudo, [ authorized_key_1, authorized_key_2, ... ], user_cert ]
#
# * if home_dir is nil then the user's home will be created in the default folder
# * if group_name_or_id is nil then the users default group will be used
# * last two elements of the array are optional
#
default["env"]["users"] = [ ]

# Override the file in which to add authorized public keys for ssh logins
default["env"]["authorized_keys_file"] = "authorized_keys"

# Pacemaker cluster
default["pacemaker_cluster_name"] = nil
default["pacemaker_mcast_address"] = nil
default["pacemaker_mcast_port"] = nil
