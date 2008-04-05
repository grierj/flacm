#!/usr/bin/ruby -w
# Skeletal Class/Module structure for FLACM
#
# Copyright:: Copyright 2006, Responsys, Inc.
# Original Author:: Grier Johnson <gjohnson@responsys.com>
#
#  This file is part of FLACM.
#
#  FLACM is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  FLACM is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with FLACM.  If not, see <http://www.gnu.org/licenses/>.
#
# Last modification:: $Date: 2008-03-19 17:18:48 -0700 (Wed, 19 Mar 2008) $

require 'flacm'
require 'yaml'
require 'socket'

module FLACM
  module Roles
    # Establish the FLACM::Roles::Function namespace.  This is the module that
    # parses functions and runs applicable function-based scripts.  This 
    # module should inherit FLACM::Roles::Generic
    #
    # TODO: Make this script lean more heavily on Generic, like it should
    #
    class Function < Generic
      def initialize(flacm_url, role, part_as_whole=false)
        @flacm_url = flacm_url
        @role = role
        @role_for_url = role.split('+')[0]
        @roles_url = @flacm_url + '/ROLES/' + @role_for_url
        super(@roles_url,part_as_whole)
      end
      def run(role=@role, root=@my_root)
        has_subroles=false
        base_role=@role
        roles_array = @role.split('+')
        if roles_array.length > 1
          has_subroles=true
          base_role = roles_array[0]
        end
        FLACM.debug(3,"Entering FLACM::Roles::Function.run")
        begin
          run_script("#{root}/#{base_role}/scripts/pre", role)
        rescue FLACM::Roles::Generic::NoScriptError
          FLACM::Log.error("Didn't find a pre-install script at \
#{root}/#{base_role}/scripts/pre")
        end

        if has_subroles
          get_subroles(@role)
          FLACM.debug(3, "Scanning false root")
          search_dir("#{@my_root}/#{@base_role}/root",false)
        end

        fix(root,role)
        sync("#{@fixroot}/#{base_role}/root/",'/')
        begin
          run_script("#{root}/#{base_role}/scripts/post", role, false)
        rescue FLACM::Roles::Generic::NoScriptError
          FLACM::Log.error("Didn't find a post-install script at \
#{root}/#{base_role}/scripts/post") 
        end
        FLACM.debug(3,"Deleting #{@my_root}")
        self.cleanup
        FLACM.debug(3,"Deleting #{@fixroot}")
        self.cleanup(@fixroot)
        FLACM.debug(3,"Leaving FLACM::Roles::Function.run")
      end

      def get_subroles(subrole)
        FLACM.debug(2,"Getting Subrole: #{subrole}")
        role_array = subrole.split('+')
        @base_role = role_array.shift if defined?(@curr_sub).nil?
        @curr_sub = String.new if defined?(@curr_sub).nil?
        if @curr_sub.empty?
          @curr_sub = role_array.shift
        else
          @curr_sub = [@curr_sub, role_array.shift].join('+')
        end
        FLACM.debug(3, "Current subrole is #{@curr_sub}")
        subrole = role_array.join('+')

        sub_url = "#{flacm_url}/root+#{@curr_sub}/"
        
        FLACM.debug(3, "Creating new data source")
        data_source = FLACM::Data::Source.new(sub_url)
        FLACM.debug(3, "Putting data in false root")
        data_source.put_in("#{@my_root}/#{@base_role}/root/")

        if role_array.length > 0
          get_subroles(subrole)
        end

      end

      def self.find(source)
        dir = FLACM::Data::Source::Local.make_root
        data_source = FLACM::Data::Source.new(source)
        data_source.get(dir)
        file_path = File.basename(data_source.location)
        begin
          functions = YAML.load_file("#{dir}/#{file_path}")
        rescue NoMethodError
          # Support for old versions of YAML, the above is cleaner though.
          functions = File.open( "#{dir}/#{file_path}" ) { |line| \
            YAML::load(line) }
        end
        data_source.clean(dir)
        return functions
      end
      def self.parse(source_yaml, my_host=Socket.gethostname)
        my_roles = Array.new
        source_yaml.each_key do |function|
          source_yaml[function].each do |host|
            FLACM.debug(3,"Checking if #{host} is the same as #{my_host}")
            if host == my_host
              my_roles.push(function)
            end
          end
        end
        return my_roles
      end
    end
  end
end
