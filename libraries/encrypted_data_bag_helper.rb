
#
# Author: Mevan Samaratunga
# Email: mevansam@gmail.com
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

        def get_encryption_secret(node)

            data_bag_secret_file = node["env"]["secret_file_path"] ||
                Chef::Config[:encrypted_data_bag_secret] ||
                '/etc/chef/encrypted_data_bag_secret'

            if data_bag_secret_file
                return Chef::EncryptedDataBagItem.load_secret(data_bag_secret_file)
            else
                return nil
            end
        end

    end
end
