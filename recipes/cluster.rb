#
# Cookbook Name:: sysutils
# Recipe:: cluster
#

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
ipaddress = node["ipaddress"]

cluster_name = nil
cluster_members = nil
mcast_address = nil
mcast_port = nil
is_cluster = false

node["clusters"].each_pair do |name, info|

    members = info["members"]

    members.each do |member|

        if ipaddress==member[0]

            cluster_name = name
            cluster_members = members
            mcast_address = info["mcast_address"]
            mcast_port = info["mcast_port"]
            is_cluster = true
            break
        end

        break if is_cluster
    end
end 

if is_cluster

    cluster_nodes = search(:node, "cluster_name:#{cluster_name} AND cluster_authkey:*")

    auth_key = nil
    if cluster_nodes.size>0
        auth_key = cluster_nodes.first["cluster_authkey"]
        node.set["cluster_authkey"] = auth_key
    end

    initializing_node = search(:node, "cluster_name:#{cluster_name} AND cluster_initializing_node:true")
    node.override["cluster_initializing_node"] = true if initializing_node.size==0
    node.override["cluster_name"] = cluster_name

    case platform_family
        when "debian"

            package "pacemaker"
            package "corosync"
            package "cluster-glue"
            package "resource-agents"

            script "configure service startup" do
                interpreter "bash"
                user "root"
                code <<-EOH

                    update-rc.d -f pacemaker remove
                    update-rc.d pacemaker start 50 1 2 3 4 5 . stop 01 0 6 .

                    if [ -z "`grep START /etc/default/corosync`" ]; then
                        echo "START=yes" >> /etc/default/corosync
                    else
                        sed -i "s|#*START=.*|START=yes|" /etc/default/corosync
                    fi

                    touch /etc/corosync/startup.initialized
                EOH
                notifies :run, "script[restart cluster node services]"
                only_if { !File.exists?("/etc/corosync/startup.initialized") }
            end

            if auth_key.nil? || auth_key.empty?

                ruby_block "generating cluster authorization key" do
                    block do

                        system 'corosync-keygen -l'
                        system 'xxd /etc/corosync/authkey > /etc/corosync/authkey.hex'
                        system 'chmod 0400 /etc/corosync/authkey.hex'

                        auth_key = `cat /etc/corosync/authkey.hex | awk '{printf("%s\\n", \$0)}'`
                        node.set["cluster_authkey"] = auth_key
                        node.save

                        Chef::Log.debug("Saved generated authorization key: #{auth_key}")
                    end
                    notifies :run, "script[restart cluster node services]"
                end
            else
                ruby_block "saving cluster authorization key" do
                    block do
                         Chef::Log.debug("Using authorization key: #{auth_key}")

                        system 'cat /etc/corosync/authkey.hex | xxd -r > /etc/corosync/authkey'
                        system 'chmod 0400 /etc/corosync/authkey'
                    end
                    action :nothing
                    notifies :run, "script[restart cluster node services]"
                end

                file "/etc/corosync/authkey.hex" do
                    owner "root"
                    group "root"
                    mode "0400"
                    content auth_key
                    notifies :create, "ruby_block[saving cluster authorization key]", :immediately
                end
            end

            bind_net_address = ipaddress.gsub(/\.\d+$/, '.0')
            template "/etc/corosync/corosync.conf" do
                source "corosync.conf.erb"
                mode "0644"
                variables(
                    :cluster_name => cluster_name,
                    :cluster_members => cluster_members,
                    :bind_net_address => bind_net_address,
                    :mcast_address => mcast_address,
                    :mcast_port => mcast_port
                )
                notifies :run, "script[restart cluster node services]"
            end

            template "/etc/hosts" do
                source "cluster_node_hosts.erb"
                mode "0644"
                variables(
                    :cluster_members => cluster_members
                )
                notifies :run, "script[restart cluster node services]"
            end

            script "restart cluster node services" do
                interpreter "bash"
                user "root"
                code <<-EOH
                    service pacemaker stop
                    service corosync stop
                    service corosync start
                    sleep 10
                    service pacemaker start
                EOH
                action :nothing
            end
        else
            Chef::Application.fatal!("Clustering is not supported on the \"#{platform_family}\" family of platforms.", 999)
    end
end
