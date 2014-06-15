# Copyright 2013, Copyright (c) 2012-2012 Fidelity Investments.

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

default["env"]["user_certs"] = [ ]
default["env"]["other_certs"] = [ ]
default["env"]["known_hosts"] = [ ]

default["env"]["user_groups"] = [ ]