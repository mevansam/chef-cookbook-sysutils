# Copyright 2014, Copyright (c) 2012-2012 Fidelity Investments.

require 'rubygems'
require 'rubygems/dependency_installer'
require 'rubygems/doc_manager'

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
