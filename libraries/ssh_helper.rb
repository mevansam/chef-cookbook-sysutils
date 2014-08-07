# Copyright 2013, Copyright (c) 2012-2012 Fidelity Investments.

install_gem("net-ssh") if !gem_installed?("net-ssh")
require "net/ssh"

install_gem("net-scp") if !gem_installed?("net-scp")
require 'net/scp'

module OSEnv
    module Helper

        class SSH

            def initialize(host, user, key)
                @host = host
                @user = user
                @key = key
          	end

            def create_ssh_session()
                
                Chef::Log.debug("Starting ssh session to #{@user}@#{@host}.")
                
                if @key.nil?
                    Chef::Application.fatal!("No password or key data provided for ssh session.", 999)

                elsif @key.start_with?("-----BEGIN RSA PRIVATE KEY-----")
                    Chef::Log.debug("Using ssh key.")
                    
                    return Net::SSH.start(@host, @user, 
                        { 
                            :key_data => @key, 
                            :user_known_hosts_file => "/dev/null"
                         } )
                else
                    Chef::Log.debug("Using ssh password.")
                    
                    return Net::SSH.start(@host, @user, 
                        { 
                            :password => @key, 
                            :user_known_hosts_file => "/dev/null"
                        } )
                end                
            end

            def copy(src = nil, dest = nil, clean = false, verbose = false)

            	Chef::Log.debug("Executing remote copy from #{src} to #{@host}:#{dest}.")

                ssh = create_ssh_session()
                ssh.exec!("rm -fr #{dest}") if clean
                ssh.scp.upload!(src, dest, :recursive => true, :verbose => verbose)
            ensure
                ssh.close
            end

            def execute(cmd)

                Chef::Log.debug("Executing remote command on host #{@host}: #{cmd}")
                ssh = create_ssh_session()
                result = ssh.exec!(cmd)
            ensure
                ssh.close
            end

            def execute_ex(cmd, env = {}, src = nil, dest = nil, sudo = false, clean = false, verbose = false)
                
                unless cmd.nil? || cmd.empty?

                    Chef::Log.debug("Executing remote command on host #{@host}: #{cmd}")
                    
                    output = StringIO.new
                    copy(src, dest, clean, verbose) if !src.nil? && !dest.nil?
                    
                    environment = env.map { |k,v| "export #{k}=#{v}" }.join("; ")
                    environment += ";" if environment.length > 0
                    
                    if sudo
                        tmp_cmd_file = "/tmp/cmd#{SecureRandom.uuid}"
                        cmd = "#{environment}" \
                            "echo \"#{cmd}\" > #{tmp_cmd_file} && " \
                            "chmod 755 #{tmp_cmd_file} && " \
                            "sudo -E su -c #{tmp_cmd_file} && " \
                            "rm -f #{tmp_cmd_file}"
                    else
                        cmd = "#{environment}#{cmd}"
                    end

                    ssh = create_ssh_session()
                    begin
                        channel = ssh.open_channel do |ch|
                            
                            ch.request_pty do |_, success1|
                                Chef::Application.fatal!("Could not execute command #{command} on remote host #{@primary_hostname}", 999) unless success1
                                
                                ch.exec(cmd) do |_, success2|
                                    
                                    Chef::Application.fatal!("Could not execute command #{command} on remote host #{@primary_hostname}", 999) unless success2
                                    
                                    ch.on_data do |_, data|
                                        output.print(data)
                                        data.split("\n").each { |line| puts "#{@host}: #{line}" } if verbose
                                    end

                                    ch.on_extended_data do |_, _, data|
                                        output.print(data)
                                        data.split("\n").each { |line| puts "#{@host}: #{line}" } if verbose
                                    end
                                end
                            end
                        end
                        channel.wait
                    ensure
                        ssh.close
                    end

                    result = "#{output.string}"
                    return result
                end
            end

        end

    end
end