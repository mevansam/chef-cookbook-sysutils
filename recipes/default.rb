#
# Cookbook Name:: sysutils
# Recipe:: default
#
# Author: Mevan Samaratunga
# Email: mevansam@gmail.com
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

platform_family = node['platform_family']

# Set up proxies if provided
["http_proxy", "https_proxy", "no_proxy"].each do |proxy_config|

    if node["env"].has_key?(proxy_config) && 
        !node["env"][proxy_config].nil? && 
        !node["env"][proxy_config].empty?

        Chef::Config[proxy_config] = ENV[proxy_config] = ENV[proxy_config.upcase] = node["env"][proxy_config]

    elsif !Chef::Config[proxy_config].nil? && 
        !Chef::Config[proxy_config].empty?

        unless ENV[proxy_config] || ENV[proxy_config.upcase]
            ENV[proxy_config] = ENV[proxy_config.upcase] = Chef::Config[proxy_config]
        end
        node.set["env"][proxy_config] = Chef::Config[proxy_config]
        node.save
    end
end

http_proxy = node["env"]["http_proxy"]
if !http_proxy.nil? && !http_proxy.empty?

    sysutils_global_proxy "http proxy" do
        http_proxy http_proxy
        https_proxy node["env"]["https_proxy"]
        ftp_proxy node["env"]["ftp_proxy"]
        no_proxy node["env"]["no_proxy"]
    end
end

# Check if extra storage was provided and if it was format and mount it

if node["env"].has_key?("data_disk") && !node["env"]["data_disk"].nil? && !node["env"]["data_disk"].empty? &&
    node["env"].has_key?("data_path") && !node["env"]["data_path"].nil? && !node["env"]["data_path"].empty?

    data_disk = node["env"]["data_disk"]
    data_path = node["env"]["data_path"]

    script "prepare data disk" do
        interpreter "bash"
        user "root"
        cwd "/tmp"
        code <<-EOH

            if [ -n "$(lsblk | grep #{data_disk.split("/").last})" ] && \
                [ -z "$(blkid | grep #{data_disk})"]; then

                echo "**** Formating data disk #{data_disk} with ext4 file system..."
                mkfs.ext4 -F #{data_disk}
            fi
        EOH
    end

    directory data_path do
        recursive true
    end

    mount data_path do
        device data_disk
        fstype "ext4"
        action [:mount, :enable]
    end
end

# Update sysctl settings

execute "reload sysctl" do
    command "sysctl -p /etc/sysctl.conf"
    action :nothing
end

unless node["env"]["sysctl_remove"].empty?
    sysutils_config_file "/etc/sysctl.conf" do
        values node["env"]["sysctl_remove"]
        format_in Regexp.new('(\S+)\s+=\s+(.+)')
        format_out "%s = %s"
        daemon_config_dir "/etc/sysctl.d"
        action :remove
        notifies :run, "execute[reload sysctl]"
    end
end
unless node["env"]["sysctl_add"].empty?
    sysutils_config_file "/etc/sysctl.conf" do
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
    sysutils_config_file "/etc/security/limits.conf" do
        values node["env"]["ulimit_remove"]
        format_in Regexp.new('(\S+)\s+(\S+)\s+(\S+)\s+(\S+)')
        format_out "%-16s%-8s%-16s%s"
        daemon_config_dir "/etc/security/limits.d"
        action :remove
    end
end
unless node["env"]["ulimit_add"].empty?
    sysutils_config_file "/etc/security/limits.conf" do
        values node["env"]["ulimit_add"]
        format_in Regexp.new('(\S+)\s+(\S+)\s+(\S+)\s+(\S+)')
        format_out "%-16s%-8s%-16s%s"
        daemon_config_dir "/etc/security/limits.d"
        action :add
    end
end

# Enable/Disable firewall

if !node["env"]["firewall"].nil?

    if !node["env"]["firewall"]

        case platform_family

            when "fedora", "rhel"
                script "disable firewall" do
                    interpreter "bash"
                    user "root"
                    code <<-EOH
                        service iptables save
                        service iptables stop
                        chkconfig iptables off
                    EOH
                end

            when "debian"
                if platform?("ubuntu")
                    execute '[ -n "$(ufw status | grep inactive)" ] || (ufw disable)' 
                end
        end
    end
end

# Setup package repos and install packages

needs_update = false

if !node.attribute?("package_repos_updated") &&
    node["env"]["package_repos"].has_key?(platform_family) &&
    node["env"]["package_repos"][platform_family].size > 0

    package_repos = node['env']['package_repos']['added'] || [ ]

    node["env"]["package_repos"][platform_family].each do |repo_detail|

        repo_detail_desc = "#{repo_detail}"
        if !package_repos.include?(repo_detail_desc)

            case platform_family
                when "fedora", "rhel"
                    execute "adding yum repo '#{repo_detail}'" do
                        command "yum-config-manager --add-repo #{repo_detail}"
                    end

                when "debian"

                    name = repo_detail[0] 
                    uri = repo_detail[1]
                    distribution = (repo_detail.size > 2 ? repo_detail[2] : node['lsb']['codename'])
                    components = (repo_detail.size > 3 ? repo_detail[3].split : [ "main" ])
                    keyserver = (repo_detail.size > 4 ? repo_detail[4] : nil)
                    key = (repo_detail.size > 5 ? repo_detail[5] : nil)
                    
                    apt_repository name do
                        uri uri
                        distribution distribution
                        components components
                        keyserver keyserver
                        key key
                    end
            end
            package_repos << repo_detail_desc
            needs_update = true
        end
    end
    node.set['env']['package_repos']['added'] = package_repos
    node.save
end

if needs_update || !node['env']['package_repos']['cache_updated']

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
                command "
                    apt-get -y --force-yes install ubuntu-cloud-keyring;
                    apt-get -y --force-yes install gplhost-archive-keyring;
                    apt-get update
                "
            end
    end

    node.set["env"]["package_repos"]["cache_updated"] = true
    node.save
end

if node["env"]["packages"].has_key?(platform_family)

    node["env"]["packages"][platform_family].each do |pkg| 

        case platform_family
            when "debian"

                if pkg.kind_of?(Array)

                    execute "apt-get seed commands" do
                        command pkg[0]
                    end
                    package pkg[1]
                else
                    package pkg
                end
            else        
                package pkg
        end
    end
end

node["env"]["packages"]["pip"].each \
    { |pkg| execute "pip install #{pkg}" } if node["env"]["packages"].has_key?("pip")

# Create additional groups and users

groups = node["env"]["groups"]
if !groups.nil? &&
    !groups.empty?

    groups.each do |g|
        group g
    end
end

authorized_keys_file = node["env"]["authorized_keys_file"]
users = node["env"]["users"]
if !users.nil? &&
    !users.empty?

    users.each do |u|

        if !u.kind_of?(Array) || u.size < 4
            Chef::Application.fatal!("default[env][users] must be an array of [ user_name, group_name_or_id, home_dir, is_passwordless_sudo ]", 999)
        end

        user u[0] do
            supports :manage_home => true
            home u[1]
            gid u[2] 
            shell "/bin/bash"
        end

        if u[3]
            sudo u[0] do
                user u[0]
                nopasswd true
                defaults [ '!requiretty' ]
            end
        end

        sysutils_user_certs u[0] do
            cert_data (u.size==6 ? u[5] : nil)
            authorized_keys (u.size==5 ? u[4] : nil)
            authorized_keys_file authorized_keys_file
        end
    end
end

# Setup cron jobs

if node["env"]["cron_jobs"]

    # Ensure cron service is installed
    include_recipe 'cron::default'

    node["env"]["cron_jobs"].each do |name, params|

        Chef::Log.info("Adding cron job '#{name}' with params: #{params}")

        cron_d name do

            predefined_value params["predefined_value"] if params["predefined_value"]

            command params["command"]

            minute   params["minute"]  if params["minute"]
            hour     params["hour"]    if params["hour"] 
            day      params["day"]     if params["day"]
            month    params["month"]   if params["month"]
            weekday  params["weekday"] if params["weekday"]

            user        params["user"]        if params["user"]
            mailto      params["mailto"]      if params["mailto"]
            path        params["path"]        if params["path"]
            home        params["home"]        if params["home"]
            shell       params["shell"]       if params["shell"]
            comment     params["comment"]     if params["comment"]
            environment params["environment"] if params["environment"]
            mode        params["mode"]        if params["mode"]
        end
    end
end

# Export directories via NFS

if node["env"]["exports"]

    # Ensure nfs server is installed
    include_recipe 'nfs::server'

    node["env"]["exports"].each do |export|

        path = export['path']
        directory path do
            mode '0777'
            recursive true
        end

        nfs_export path do
            network export['network']
            writeable export['writeable']
            sync export['sync']
            options export['options']
        end
    end
end

if node["env"]["imports"]

    # Ensure nfs client is installed
    include_recipe 'nfs'

    node["env"]["imports"].each do |import|

        mount_path = import['mount_path']

        directory mount_path do
            group import['group'] if import['group']
            owner import['owner'] if import['owner']
            recursive true
        end

        mount mount_path do
          device "#{import['host']}:#{import['path']}"
          fstype "nfs"
          options import['options'] || 'rw'
          action [:mount, :enable]
        end
    end
end
