#
# Cookbook Name:: sysutils
# Recipe:: cluster
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

cluster_name = node["pacemaker_cluster_name"]
unless cluster_name.nil?

    mcast_address = node["pacemaker_mcast_address"]
    mcast_port = node["pacemaker_mcast_port"]

    cluster_query = "pacemaker_cluster_name:#{cluster_name} AND chef_environment:#{node.chef_environment}"

    cluster_members = [ ]
    search(:node, cluster_query).each do |cluster_node|

        Chef::Log.info("Found cluster node '#{cluster_node.name}' for role '#{cluster_name}': " +
            "ipaddress = #{cluster_node["ipaddress"]}" +
            "fqdn = #{cluster_node["fqdn"]}, " +
            "hostname = #{cluster_node["hostname"]}")

        cluster_members << [
            cluster_node["ipaddress"],
            cluster_node["fqdn"],
            cluster_node["hostname"] ]
    end

    unless shell("which crm", true).empty?
        shell("crm status").lines do |l|

            if l=~/Node .* UNCLEAN \(offline\)/

                f = l.split
                crm_node_id = f[2][/\((.*)\)/, 1]
                crm_node_name = f[1]

                Chef::Log.info("Removing Unclean offline node: id=#{crm_node_id}, name=#{crm_node_name}")

                shell!("crm_node --force -R #{crm_node_id}")
                shell!("cibadmin --delete --obj_type nodes --crm_xml '<node uname=\"#{crm_node_name}\"/>'")
                shell!("cibadmin --delete --obj_type status --crm_xml '<node_state uname=\"#{crm_node_name}\"/>'")
            end
        end
    end

    auth_cluster_nodes = search(:node, "#{cluster_query} AND cluster_authkey:*")

    auth_key = nil
    if auth_cluster_nodes.size>0
        auth_key = auth_cluster_nodes.first["cluster_authkey"]
        node.set["cluster_authkey"] = auth_key
    end

    initializing_node = search(:node, "#{cluster_query} AND cluster_initializing_node:true")
    node.set["cluster_initializing_node"] = true if initializing_node.size==0
    node.save

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

            cluster_members.each do |member|

                hostsfile_entry member[0] do
                    hostname member[1]
                    aliases [ member[2] ]
                    comment 'Required by corosync to discover cluster members'
                end
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
