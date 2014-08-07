#
# Cookbook Name:: osenv
# Recipe:: test
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

Chef::Log.info("*****************************************")
Chef::Log.info("***** Running on OS platform: \"#{node.platform}\"")
Chef::Log.info("***** Chef server version: \"#{node[:chef_packages][:chef][:version]}\"")
Chef::Log.info("***** Chef environment: \"#{node.chef_environment}\"")
Chef::Log.info("*****************************************")

# dns_entry "vc2c09mmk3297.fmr.com" do
# 	address "10.135.79.64"
# 	name_alias "cloudproxy-d.fmr.com"
# 	provider Chef::Provider::DnsEntry::Qip
# end

# dns_entry "osenvtest.fmr.com" do
# 	address "192.168.1.1"
# 	provider Chef::Provider::DnsEntry::Qip
# end

# dns_entry "osenvtest.fmr.com" do
# 	address "10.135.79.64"
# 	provider Chef::Provider::DnsEntry::Qip
# 	action :delete
# end

# dns_entry "osenvtest.fmr.com" do
# 	address "192.168.1.1"
# 	provider Chef::Provider::DnsEntry::Qip
# 	action :delete
# end
