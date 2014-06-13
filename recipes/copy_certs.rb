#
# Cookbook Name:: osenv
# Recipe:: copy_certs
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
# Install packages & certs provided within cookbook repo

require "set"

cb_paths = Chef::Config["cookbook_path"]
if !cb_paths.nil? && 
    cb_paths.is_a?(Array) && 
    cb_paths.size > 0

    # Install any certificates provided in a 
    # cookbook repo's certificates folder
    
    cert_dir = File.dirname(cb_paths[0]) + "/certificates/"
    if Dir.exists?(cert_dir)
        
        Chef::Log.debug("Certificate directory available at: #{cert_dir}")
        
        other_certs = node["env"]["other_certs"]
        known_hosts = node["env"]["known_hosts"]
        
        node["env"]["user_certs"].each do |user|
            
            cert_file = cert_dir + user + ".crt"
            
            ruby_block "installing ssh certificates for #{user}" do
                block do
                    user_home = `echo ~#{user}`.split[0]
                    if Dir.exists?(user_home)
                        
                        ssh_dir = user_home + "/.ssh/"
                        id_rsa_file = ssh_dir + "id_rsa"
                        known_hosts_file = ssh_dir + "known_hosts"
                        
                        cert_data = IO.read(cert_file)
                        group = `groups #{user}`.split[2]
                        
                        r = Chef::Resource::Directory.new(ssh_dir, run_context)
                        r.owner user
                        r.group group
                        r.run_action(:create)
                        
                        r = Chef::Resource::File.new(id_rsa_file, run_context)
                        r.content cert_data
                        r.owner user
                        r.group group
                        r.mode 0400
                        r.run_action(:create)
                        
                        other_certs.each do |cert|
                            other_cert_file = cert_dir + cert
                            if File.exists?(other_cert_file)
                                r = Chef::Resource::File.new(ssh_dir + cert, run_context)
                                r.content IO.read(other_cert_file)
                                r.owner user
                                r.group group
                                r.mode 0400
                                r.run_action(:create)
                            end
                        end
                        
                        r = Chef::Resource::File.new(known_hosts_file, run_context)
                        r.owner user
                        r.group group
                        r.not_if { File.exists?(known_hosts_file) }
                        r.run_action(:create)
                        
                        r = Chef::Resource::RubyBlock.new("update known hosts", run_context)
                        r.block do
                            hosts = Set.new
                            IO.readlines(known_hosts_file).each do |known_host|
                                host_fields = known_host.split(/,|\s+/)
                                hosts << host_fields[0]
                                hosts << host_fields[1]
                            end
                            File.open(known_hosts_file, 'a') do |file|
                                known_hosts.each do |host|
                                    unless hosts.include?(host)
                                        Chef::Log.debug("Adding host \"#{host}\" to \"#{known_hosts_file}\".")
                                        file.write(`ssh-keyscan -t rsa #{host}`)
                                    end
                                end
                            end
                        end
                        r.run_action(:create)
                    else
                        Chef::Log.warn("User \"#{user}\" does not exist or does not have a home directory.")
                    end
                end
                only_if { File.exists?(cert_file) }
            end
        end
    end

end
