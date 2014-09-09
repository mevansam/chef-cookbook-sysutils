#
# Author:: Mevan Samaratunga (<mevansam@gmail.com>)
# Cookbook Name:: sysutils
# Resource: user_certs
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

actions :add, :authorize

attribute :cert_data, :kind_of => String, :default => nil
attribute :other_cert_data, :kind_of => Hash, :default => { }
attribute :authorized_keys, :kind_of => Array, :default => [ ]

# If data bag exists for the user then all of the above values are taken from the bag
attribute :data_bag, :kind_of => String, :default => "users"

# The default authorized keys file. This maybe overriden if the 
# system is configured to use additional authorized key files.
attribute :authorized_keys_file, :kind_of => String, :default => "authorized_keys"

# List of know hosts whose keys will be saved
attribute :known_hosts, :kind_of => Array,  :default => [ ]

def initialize(*args)
    super
    @resource_name = :user_certs
    @action = :add
end
