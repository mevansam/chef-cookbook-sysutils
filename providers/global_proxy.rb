#
# Author:: Mevan Samaratunga (<mevansam@gmail.com>)
# Cookbook Name:: osenv
# Provider: global_proxy
#
# Copyright 2013, Mevan Samaratunga
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

action :install do

    http_proxy = new_resource.http_proxy
    https_proxy = (new_resource.https_proxy.nil? || new_resource.https_proxy.empty? ? http_proxy : new_resource.https_proxy)
    ftp_proxy = (new_resource.ftp_proxy.nil? || new_resource.ftp_proxy.empty? ? http_proxy : new_resource.ftp_proxy)
    
    no_proxy = "localhost,127.0.0.1,#{node["hostname"]},#{node["fqdn"]},#{node["ipaddress"]}"
    if !new_resource.no_proxy.nil? && !new_resource.no_proxy.empty?
        no_proxy += ",#{new_resource.no_proxy}"
    end

    template "/etc/profile.d/proxy_inits.sh" do
        source "proxy_inits.sh.erb"
        mode "0755"
        variables(
            :http_proxy => http_proxy,
            :https_proxy => https_proxy,
            :no_proxy => no_proxy,
            :host_ip => node["ipaddress"]
        )
    end

    script "configure proxy_inits to run for non-login shell sessions" do
        interpreter "bash"
        user "root"
        cwd "/tmp"
        code <<-EOH
            if [ -e /etc/bashrc ]; then
                sed -i '/proxy_inits.sh/d' /etc/bashrc
                sed -i '2i [ -r /etc/profile.d/proxy_inits.sh ] && source /etc/profile.d/proxy_inits.sh' /etc/bashrc
            elif [ -e /etc/bash.bashrc ]; then
                sed -i '/proxy_inits.sh/d' /etc/bash.bashrc
                sed -i '2i [ -r /etc/profile.d/proxy_inits.sh ] && source /etc/profile.d/proxy_inits.sh' /etc/bash.bashrc
            end            
        EOH
    end
    
    case
        when platform_family?("rhel", "fedora")

            osenv_config_file "/etc/yum.conf" do
                values [ 
                    [ "proxy", http_proxy ]
                ]
                format_in Regexp.new('(\S+)\s*=\s*(\S+)\s*')
                format_out "%s=%s"
                action :add
            end

        when platform_family?("debian")

            osenv_config_file "/etc/apt/apt.conf.d/01proxy" do
                values [ 
                    [ "Acquire::http::Proxy", http_proxy ], 
                    [ "Acquire::https::Proxy", https_proxy ], 
                    [ "Acquire::ftp::Proxy", ftp_proxy ] 
                ]
                format_in Regexp.new('(\S+)\s+\"(\S+)\";')
                format_out "%s \"%s\";"
                comment_format "//"
                daemon_config_dir "/etc/apt/apt.conf.d"
                action :add
            end
    end

end
