#
# Author:: Mevan Samaratunga (<mevansam@gmail.com>)
# Cookbook Name:: sysutils
# Resource: global_proxy
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

actions :install

attribute :http_proxy, :kind_of => String, :required => true
attribute :https_proxy, :kind_of => String
attribute :ftp_proxy, :kind_of => String
attribute :no_proxy, :kind_of => String

def initialize(*args)
    super
    @resource_name = :global_proxy
    @action = :install
end
