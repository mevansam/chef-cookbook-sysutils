#
# Author:: Mevan Samaratunga (<mevansam@gmail.com>)
# Cookbook Name:: osenv
# Resource: config_file
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

actions :add, :remove
default_action :add

attribute :values, :kind_of => Array, :required => true
attribute :format_in, :kind_of => Regexp, :required => true
attribute :format_out, :kind_of => String, :required => true
attribute :daemon_config_dir, :kind_of => String
attribute :comment_format, :kind_of => String, :default => "#"
