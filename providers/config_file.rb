#
# Author:: Mevan Samaratunga (<mevansam@gmail.com>)
# Cookbook Name:: sysutils
# Provider: config_file
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

require "fileutils"

def whyrun_supported?
    true
end

action :add do
    file_data = get_updated_config_file_data(
        new_resource.values, [], 
        new_resource.format_in, new_resource.format_out, 
        new_resource.name, new_resource.daemon_config_dir,
        new_resource.comment_format )
        
    unless file_data.empty?
        converge_by("Adding #{ @new_resource }") do
            write_config_file_data(file_data)
        end
    end

    if !new_resource.owner.nil?
        file new_resource.name do
            owner new_resource.owner
            group new_resource.group
            mode "0644"
            action :touch
        end
    end
end

action :remove do
    file_data = get_updated_config_file_data(
        [], new_resource.values, 
        new_resource.format_in, new_resource.format_out, 
        new_resource.name, new_resource.daemon_config_dir,
        new_resource.comment_format )
        
    unless file_data.empty?
        converge_by("Removing #{ @new_resource }") do
            write_config_file_data(file_data)
        end
    end
end
