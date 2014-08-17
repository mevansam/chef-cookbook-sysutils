# Copyright (c) 2014 Fidelity Investments.

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

default["env"]["package_repos"]["rhel"] = [ ]

# Each repo should be an array of [ name uri, distribution, components, keyserver, key ]
# Only the name and uri are required and all the other values are optional
default["env"]["package_repos"]["debian"] = [ ]

default["env"]["packages"]["rhel"] = [ ]

# Each package is either a string or an array of [ cmd, package ] where
# cmd is a list of commands to execute in the shell such as debconf
# selections.
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

# This is an array for arrays of clusters. If this current 
# server is in one of these clusters then it will be added
# to that pacemaker cluster. All pacemaker configuration
# will be done using the unicast protocol.
#
# example:
#
#   * note: if use_mcast is true then members will be ignored. This
#           assumes that your switches have multicast enabled. Otherwise
#           the cluster will be configured to use unicast.
#
#   "env" => {
#       "clusters" => {
#           "haproxy" => {
#               "members" => [ 10.1.1.1, 10.1.1.2, 10.1.1.3 ],
#               "use_mcast" => true,
#               "mcast_address" => "239.255.42.1",
#               "mcast_port" => 5405
#       }
#   }
#
default["env"]["clusters"] = [ ]
