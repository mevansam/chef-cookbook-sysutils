# Copyright 2014, Copyright (c) 2012-2012 Fidelity Investments.

default["env"]["http_proxy"] = nil
default["env"]["https_proxy"] = nil
default["env"]["ftp_proxy"] = nil
default["env"]["no_proxy"] = nil

default["env"]["sysctl_add"] = [ ]
default["env"]["sysctl_remove"] = [ ]

default["env"]["ulimit_add"] = [ ]
default["env"]["ulimit_remove"] = [ ]

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