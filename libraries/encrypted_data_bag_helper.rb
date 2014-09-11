# Copyright (c) 2014 Fidelity Investments.
#
# Author: Mevan Samaratunga
# Email: mevan.samaratunga@fmr.com
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

module ::SysUtils # rubocop:disable Documentation

    module Helper

        def get_encryption_secret

            secret_file = node["env"]["secret_file_path"]
            databag_secret_file = nil

            if !secret_file.nil? && !secret_file.empty? && ::File.exist?(secret_file)
                data_bag_secret_file = secret_file
            elsif !Chef::Config[:encrypted_data_bag_secret].empty?
                data_bag_secret_file = Chef::Config[:encrypted_data_bag_secret]
            end

            if data_bag_secret_file
                return Chef::EncryptedDataBagItem.load_secret(data_bag_secret_file)
            else
                return nil
            end
        end

    end
end