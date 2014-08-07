# Copyright 2013, Copyright (c) 2012-2012 Fidelity Investments.

require 'chef/resource'

class Chef
	class Resource

		class DnsEntry < Chef::Resource

			def initialize(name, run_context=nil)
				super
				
				@resource_name = :dns_entry

				@provider = Chef::Provider::DnsEntry::NoOp

				@action = :create
				@allowed_actions = [:create, :delete]

				@name = name
				@description = description
				@address = nil
				@name_alias = nil
			end

			# Description of this mapping for auditing
			def description(arg=nil)
				set_or_return(:description, arg, :kind_of => String)
			end

			# IP address to map name to
			def address(arg=nil)
				set_or_return(:address, arg, :kind_of => String)
			end

			# Name to alias give dns name with
			def name_alias(arg=nil)
				set_or_return(:name_alias, arg, :kind_of => String)
			end
		end

	end
end
