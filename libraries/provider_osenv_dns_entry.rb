# Copyright 2013, Copyright (c) 2012-2012 Fidelity Investments.

require 'chef/provider'
require 'chef/mixin/shell_out'
require 'uri/http'
require 'erb'

class Chef
	class Provider

		class DnsEntry

			class NoOp < Chef::Provider

				def load_current_resource
					@current_resource ||= Chef::Resource::DnsEntry.new(new_resource.name)

					@current_resource.description(new_resource.description)
					@current_resource.address(new_resource.address)
					@current_resource.name_alias(new_resource.name_alias)

					@current_resource
				end

				def action_create
					Chef::Log.warn("The DNS entry provider implementation must be explicitely specified.")
				end

				def action_delete
					Chef::Log.warn("The DNS entry provider implementation must be explicitely specified.")
				end
			end

		end

	end
end
