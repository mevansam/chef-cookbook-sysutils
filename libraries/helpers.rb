# Copyright (c) 2014 Fidelity Investments.

require 'rubygems'
require 'rubygems/dependency_installer'
require 'rubygems/doc_manager'
require 'mixlib/shellout'

module ::SysUtils # rubocop:disable Documentation

    module Helper

        def gem_installed?(name, version = Gem::Requirement.default)
            version = Gem::Requirement.create version unless version.is_a? Gem::Requirement
            Gem::Specification.each.any? { |spec| name == spec.name and version.satisfied_by? spec.version }
        end

        def install_gem(name, options = {})
            version = options.fetch(:version, Gem::Requirement.default)
            generate_rdoc = options.fetch(:generate_rdoc, false)

            return if gem_installed? name, version

            installed_gems = Gem::DependencyInstaller.new.install name, version

            if generate_rdoc
                installed_gems.each { |gem| Gem::DocManager.new(gem).generate_ri }
                Gem::DocManager.update_ri_cache
            end
        end

        def shell(cmd)
            Chef::Log.debug("Executing shell command: #{cmd}")
            sh = Mixlib::ShellOut.new(cmd)
            sh.run_command
            sh.error!
            return sh.stdout.chomp
        end

        def shell!(cmd, ignore_error = false)
            Chef::Log.debug("Executing shell command: #{cmd}")
            sh = Mixlib::ShellOut.new(cmd)
            sh.run_command
            sh.error! if ignore_error
        end
    end
end