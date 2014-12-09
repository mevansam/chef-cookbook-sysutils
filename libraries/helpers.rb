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

require 'rubygems'
require 'rubygems/dependency_installer'
require 'mixlib/shellout'

module ::SysUtils # rubocop:disable Documentation

    module Helper

        def gem_installed?(name, version = Gem::Requirement.default)
            version = Gem::Requirement.create version unless version.is_a? Gem::Requirement
            Gem::Specification.each.any? { |spec| name == spec.name and version.satisfied_by? spec.version }
        end

        def install_gem(name, options = {})
            version = options.fetch(:version, Gem::Requirement.default)
            return if gem_installed? name, version
            installed_gems = Gem::DependencyInstaller.new({:document => []}).install name, version
        end

        def shell(cmd, ignore_error = false)
            Chef::Log.debug("Executing shell command: #{cmd}")
            sh = Mixlib::ShellOut.new(cmd)
            sh.run_command
            sh.error! if !ignore_error
            return sh.stdout.chomp
        end

        def shell!(cmd, ignore_error = false)
            Chef::Log.debug("Executing shell command: #{cmd}")
            sh = Mixlib::ShellOut.new(cmd)
            sh.run_command
            sh.error! if !ignore_error
        end
    end
end
