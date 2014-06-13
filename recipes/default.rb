#
# Cookbook Name:: osenv
# Recipe:: default
#
# Copyright 2013, Copyright (c) 2012-2012 Fidelity Investments.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Chef::Log.info("***** Running on OS platform \"#{node.platform}\" *****")
Chef::Log.info("***** Chef server version \"#{node[:chef_packages][:chef][:version]}\" *****")

platform_family = node['platform_family']

# Set up proxies if provided
["http_proxy", "https_proxy", "no_proxy"].each do |proxy_config|

	if node["env"].has_key?(proxy_config) && 
        !node["env"][proxy_config].nil? && 
        !node["env"][proxy_config].empty?

		ENV[proxy_config] = ENV[proxy_config.upcase] = node["env"][proxy_config]
	elsif !Chef::Config[proxy_config]
	    unless ENV[proxy_config] || ENV[proxy_config.upcase]
	        ENV[proxy_config] = ENV[proxy_config.upcase] = Chef::Config[proxy_config]
	    end
        node["env"][proxy_config] = ENV[proxy_config]
	end
end

http_proxy = node["env"]["http_proxy"]
if !http_proxy.nil? && !http_proxy.empty?

    osenv_global_proxy "http proxy" do
        http_proxy http_proxy
        https_proxy node["env"]["https_proxy"]
        ftp_proxy node["env"]["ftp_proxy"]
        no_proxy node["env"]["no_proxy"]
    end
end

# Update sysctl settings

execute "reload sysctl" do
    command "sysctl -p /etc/sysctl.conf"
    action :nothing
end

unless node["env"]["sysctl_remove"].empty?
    osenv_config_file "/etc/sysctl.conf" do
        values node["env"]["sysctl_remove"]
        format_in Regexp.new('(\S+)\s+=\s+(.+)')
        format_out "%s = %s"
        daemon_config_dir "/etc/sysctl.d"
        action :remove
        notifies :run, "execute[reload sysctl]"
    end
end
unless node["env"]["sysctl_add"].empty?
    osenv_config_file "/etc/sysctl.conf" do
        values node["env"]["sysctl_add"]
        format_in Regexp.new('(\S+)\s+=\s+(.+)')
        format_out "%s = %s"
        daemon_config_dir "/etc/sysctl.d"
        action :add
        notifies :run, "execute[reload sysctl]"
    end
end

# Update ulimit settings

unless node["env"]["ulimit_remove"].empty?
    env_config_file "/etc/security/limits.conf" do
        values node["env"]["ulimit_remove"]
        format_in Regexp.new('(\S+)\s+(\S+)\s+(\S+)\s+(\S+)')
        format_out "%-16s%-8s%-16s%s"
        daemon_config_dir "/etc/security/limits.d"
        action :remove
    end
end
unless node["env"]["ulimit_add"].empty?
    env_config_file "/etc/security/limits.conf" do
        values node["env"]["ulimit_add"]
        format_in Regexp.new('(\S+)\s+(\S+)\s+(\S+)\s+(\S+)')
        format_out "%-16s%-8s%-16s%s"
        daemon_config_dir "/etc/security/limits.d"
        action :add
    end
end

# Setup package repos and install packages

if !node.attribute?("package_repos_updated") &&
    node["env"]["package_repos"].has_key?(platform_family) &&
    node["env"]["package_repos"][platform_family].size > 0

    node["env"]["package_repos"][platform_family].each do |repo|

        case platform_family
            when "fedora", "rhel"
                execute "adding yum repo #{repo}" do
                    command "yum-config-manager --add-repo #{repo}"
                end
            when "debian"
                execute "adding apt ppa #{repo}" do
                    command "add-apt-repository #{repo}"
                end
        end
    end

    case platform_family
        when "fedora", "rhel"
            execute "update package cache" do
                command "yum clean all"
            end
            ruby_block "refresh chef yum cache" do
                block do
                    yum = Chef::Provider::Package::Yum::YumCache.instance
                    yum.reload
                    yum.refresh
                end
            end
        when "debian"
            execute "update package cache" do
                command "apt-get update"
            end
    end

    node.set['package_repos_updated'] = true
    node.save
end

if node["env"]["packages"].has_key?(platform_family)
    node["env"]["packages"][platform_family].each do |pkg|
        package pkg do
            action :install
        end
    end
end

# Create additional groups

user_groups = node["env"]["user_groups"]
if !user_groups.nil? &&
    !user_groups.empty?

    user_groups.each do |g|
        group g
    end
end
