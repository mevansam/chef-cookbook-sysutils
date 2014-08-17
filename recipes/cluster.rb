#
# Cookbook Name:: sysutils
# Recipe:: cluster
#
# Copyright (c) 2014 Fidelity Investments.
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
use_mcast = false
mcast_address = nil
mcast_port = nil
is_cluster = false

node["env"]["clusters"].each_pair do |name, info|

	members = info["members"]

	members.each do |member|

		if ipaddress == member

			cluster_name = name
			cluster_members = members
			use_mcast = info["use_mcast"]
			mcast_address = info["use_mcast"]
			mcast_port = infr["mcast_port"]
			is_cluster = true
			break
		end

		break if is_cluster
	end
end 

if is_cluster

    case platform_family
        when "debian"

        	package "pacemaker"
        	package "corosync"
        	package "cluster-glue"
        	package "resource-agentspackage"

        	service "pacemaker" do
        		provider Chef::Provider::Service::Upstart
        		action :stop
        	end
        	service "corosync" do
        		provider Chef::Provider::Service::Upstart
        		action :stop
        	end

		    script "configure service startup" do
		        interpreter "bash"
		        user "root"
		        code <<-EOH

			        update-rc.d -f pacemaker remove
			        update-rc.d pacemaker start 50 1 2 3 4 5 . stop 01 0 6 .

			        if \[ -z \"`grep START /etc/default/corosync`\" \]; then
			            echo \"START=yes\" >> /etc/default/corosync
			        else
			            sed -i \"s|#*START=.*|START=yes|\" /etc/default/corosync
			        fi

			        touch /etc/corosync/cluster_service_init_done
		        EOH
		        only_if !node["env"]["clusters"]["installed"]
		    end

			bind_net_address = ipaddress.gsub(/\.\d+$/, '.0')

		    template "/etc/corosync" do
		        source "corosync.conf.erb"
		        mode "0644"
		        variables(
		            :cluster_name => cluster_name,
		            :cluster_members => cluster_members,
		            :bind_net_address => bind_net_address,
		            :use_mcast => use_mcast,
		            :mcast_address => mcast_address,
		            :mcast_port => mcast_port
		        )
		    end

		    auth_key = node["env"]["cluster_authkey"]
		    if auth_key.nil? || auth_key.empty?

		    	sh = Mixlib::ShellOut.new("corosync-keygen; cat /etc/corosync/authkey")
  				auth_key = sh.stdout.chomp
		    end

		    file "/etc/corosync/authkey" do
		        owner "root"
		        group "root"
		        mode "0644"
		        content auth_key
		    end

		    node.set["env"]["clusters"]["installed"] = true
        else
        	Chef::Application.fatal!("Clustering is not supported on the \"#{platform_family}\" family of platforms.", 999)
    end
end
