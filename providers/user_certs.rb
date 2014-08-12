#
# Author:: Mevan Samaratunga (<mevansam@gmail.com>)
# Cookbook Name:: sysutils
# Provider: user_certs
#
# Copyright 2014, Mevan Samaratunga
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

def whyrun_supported?
    true
end

action :add do

	user = new_resource.name

	cert_data = new_resource.cert_data
	other_cert_data = new_resource.other_cert_data
	authorized_keys = new_resource.authorized_keys

	encryption_key = node["env"]["encryption_key"]
	if !encryption_key.nil?
		user_data = Chef::EncryptedDataBagItem.load(new_resource.data_bag, "#{user}.#{node.chef_environment}", encryption_key)
		if !user_data.nil?
			cert_data = user_data["cert_data"] if user_data["cert_data"]
			other_cert_data = user_data["other_cert_data"] if user_data["other_cert_data"]
			authorized_keys = user_data["authorized_keys"] if user_data["authorized_keys"]
		end
	end

	Chef::Log.debug("Contents of data bag '#{new_resource.data_bag}' item user_data[cert_data]: #{cert_data}")
	Chef::Log.debug("Contents of data bag '#{new_resource.data_bag}' item user_data[other_cert_data]: #{other_cert_data}")
	Chef::Log.debug("Contents of data bag '#{new_resource.data_bag}' item user_data[authorized_keys]: #{authorized_keys}")

	authorized_keys_file_name = new_resource.authorized_keys_file
	known_hosts = new_resource.known_hosts

	user_home = `echo ~#{user}`.split[0]
    if ::Dir.exists?(user_home)
        
        ssh_dir = user_home + "/.ssh/"
        id_rsa_file = ssh_dir + "id_rsa"
        known_hosts_file = ssh_dir + "known_hosts"
        authorized_keys_file = ssh_dir + authorized_keys_file_name
        
        group = `groups #{user}`.split[2]
        
        r = Chef::Resource::Directory.new(ssh_dir, @run_context)
        r.owner user
        r.group group
        r.run_action(:create)
        
        r = Chef::Resource::File.new(id_rsa_file, @run_context)
        r.content cert_data
        r.owner user
        r.group group
        r.mode 0400
        r.run_action(:create)

        r = Chef::Resource::File.new(known_hosts_file, @run_context)
        r.owner user
        r.group group
        r.not_if { ::File.exists?(known_hosts_file) }
        r.run_action(:create)

        r = Chef::Resource::RubyBlock.new("update known hosts", @run_context)
        r.block do
            hosts = Set.new
            ::IO.readlines(known_hosts_file).each do |known_host|
                host_fields = known_host.split(/,|\s+/)
                hosts << host_fields[0]
                hosts << host_fields[1]
            end
            ::File.open(known_hosts_file, 'a') do |file|
                known_hosts.each do |host|
                    unless hosts.include?(host)
                        Chef::Log.debug("Adding host \"#{host}\" to \"#{known_hosts_file}\".")
                        file.write(`ssh-keyscan -t rsa #{host}`)
                    end
                end
            end
        end
        r.run_action(:create)

        ssh_configs = [ ]
        other_cert_data.each do |other_cert|
            key_file = ssh_dir + other_cert["name"]
            r = Chef::Resource::File.new(key_file, @run_context)
            r.content other_cert["data"]
            r.owner user
            r.group group
            r.mode 0400
            r.run_action(:create)

            if other_cert.has_key?("hosts")
                other_cert["hosts"].each do |host|
                    ssh_configs << [ host, key_file ]
                end
            end
        end

        template "#{ssh_dir}config" do
            source "ssh_config.erb"
            owner user
            group group
            mode "0644"
            variables(
                :ssh_configs => ssh_configs
            )
        end

        public_keys = [ ]
        authorized_keys.each do |authorized_key|
        	public_keys << [ authorized_key ]
        end

		sysutils_config_file authorized_keys_file do
            owner user
            group group
		    values public_keys
		    format_in Regexp.new('(.*)')
		    format_out "%s"
		    action :add
		end
    else
        Chef::Log.warn("User \"#{user}\" does not exist or does not have a home directory.")
    end	
end

action :authorize do

	user = new_resource.name

	cert_data = new_resource.cert_data
	authorized_keys = new_resource.authorized_keys

	user_data = data_bag_item(new_resource.data_bag, user)
	if user_data.nil?
		cert_data = user_data if user_data["cert_data"]
		authorized_keys = user_data if user_data["authorized_keys"]
	end
end
