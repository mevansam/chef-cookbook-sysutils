# Copyright (c) 2014 Fidelity Investments.

require "chef"
require "fileutils"

def get_updated_config_file_data(values_to_add, values_to_remove, format_in, format_out, config_file, daemon_config_dir = nil, comment_format = "#")

    if !File.exists?(config_file)
        File.open(config_file, 'w+') { |f| f.write("") }
    end
   
    config_files = [ ] 
    if !daemon_config_dir.nil? && Dir.exists?(daemon_config_dir)
        config_files.concat(Dir.entries(daemon_config_dir).select { |e| e != "." && e != ".." }.collect { |e| "#{daemon_config_dir}/#{e}"})
    end
    unless config_files.include?(config_file)
        config_files << config_file
    end
    
    file_data = { }
    config_file_data = ""
    new_values = Array.new(values_to_add)

    Chef::Log.debug("Values to add: #{values_to_add}")
    Chef::Log.debug("Values to remove: #{values_to_remove}")

    config_files.each do |file|

        Chef::Log.debug("Checking for updates to configuration file #{file}...")
        
        lines = IO.readlines(file)
        changed = false
        update = false
        
        for i in 0..(lines.size-1)
            
            line = lines[i]
            
            unless line.nil? || line.start_with?(comment_format)
                
                values = [ ]
                line.scan(format_in) { |v| values.concat(v) }
                next if values.empty? 

                Chef::Log.debug("  - Extracted values from file: #{values}")

                values_to_remove.each do |v|
                    if values == v 
                        lines[i] = "#{comment_format}#{line}"
                        changed = true
                        break
                    end
                end

                (new_values.size-1).downto(0) do |j|

                    v = new_values[j]

                    for k in 0..(v.size-1)

                        if v[k] != values[k]
                            update = (k > 0)
                            break
                        end
                    end
                    if k > 0
                        if update
                            Chef::Log.debug("  - Updating line in #{file}: \"#{lines[i]}\"")
                            lines[i] = (format_out % v) + "\n"
                            Chef::Log.debug("  - Updated line in #{file}: \"#{lines[i]}\"")

                            update = false
                            changed = true
                        end
                        new_values.delete_at(j)
                    end
                end
            end
        end

        if file == config_file
            config_file_data = lines.join.chomp
            file_data[file] = config_file_data if changed
        else
            file_data[file] = lines.join if changed    
        end
    end

    Chef::Log.debug("New values remaining to add: #{new_values}")
    
    if new_values.size > 0
        if file_data.has_key?(config_file)
            file_data[config_file] << "\n" << new_values.collect { |v| format_out % v }.join("\n") << "\n"
        elsif !config_file_data.empty?
            file_data[config_file] = config_file_data << "\n" << new_values.collect { |v| format_out % v }.join("\n") << "\n"
        else
            file_data[config_file] = new_values.collect { |v| format_out % v }.join("\n") << "\n"
        end
    end
    
    return file_data
end

def write_config_file_data(file_data)
    file_data.each_pair do |file, data|
        Chef::Log.debug("Writing file #{file}: \n#{data}")
        ::File.open(file, "w") { |f| f.write(data) }
    end
end
