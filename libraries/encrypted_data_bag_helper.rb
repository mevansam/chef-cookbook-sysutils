# Copyright (c) 2014 Fidelity Investments.

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
