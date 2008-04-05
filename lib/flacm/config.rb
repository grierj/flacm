#!/usr/bin/ruby -w
#
# FLACM class for handling configuration (of FLACM)
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
require 'ostruct'
require 'optparse'

# Preserves all sub-modules in FLACM:: namespace.
#
module FLACM

  # Establish FLACM::Config namespace.  FLACM::Config is where FLACM
  # handles reading a FLACM configuration file that changes the behavior
  # of FLACM.
  #
  class Config
    attr_accessor :flacm_config

    # Read the configuration file, parse, and finally make variables available
    # as accessors.
    #
    # Args:
    # - file: String -- The configuration file we're interested in
    # Returns:
    # - self
    #
    def initialize(file)
      @file = file
      @flacm_config = Hash.new

      if File.exists?(@file)
        FLACM.debug(3, "#{@file} exists, checking parsing")
        self.parse(@file)
      else
        FLACM.debug(3, "#{@file} does not exists, throwing error")
        raise FLACM::Config::ConfigFileError
      end
      return self
    end
    
    # Check to make sure we've got a FLACM config file.  It's not worth parsing
    # something we don't care about
    #
    # Args:
    # - file: String -- The configuration file we want to check
    #
    # Returns:
    # - boolean
    #
    def parse(file)
      config = YAML.load_file(file)
      if config.has_key?('LIB_DIR')
        FLACM.debug(3, "#{LIB_DIR} is the configured library directory")
        @lib_path = config['LIB_DIR']
      end
      if config.has_key?('NEW_FROM_PART')
        FLACM.debug(3, "Create new files from a part file: #{NEW_FROM_PART}")
        @new_file_from_part = config['NEW_FROM_PART']
      end
    end

    # A slightly more specific ConfigFileError for when the file doesn't parse
    # or doesn't exist.
    class ConfigFileError < RuntimeError
    end
    # A class to deal with command line arguments.  There's not good way
    # to shorten command line arguments, so I'm using "CLI"
    module CLI
      def self.parse(command_args)
        options = OpenStruct.new 
        options.ignore = false
        options.no_ignore = false
        options.daemon = false
        options.verbose = 0
        options.quiet = false
        options.force = false
        options.status = false
        options.source = String.new
        options.roles_source = String.new
        options.roles_to_run = Array.new

        opts = OptionParser.new do |opts|
          opts.banner = "FLACM Likes Automation and Configuration Management\n"
          opts.banner << "\n"
          opts.banner << "FLACM is an in-house configuration management agent "
          opts.banner << "that can run from init or\ncron.  For more "
          opts.banner << "information please see:\n"
          opts.banner << "http://wiki.corp.responsys.com/OPS/Sysops/Services/FLACM/AdminGuide\n"
          opts.banner << "\n"
          opts.banner << "Usage: #{File.basename($0)} [options] \
[<role1> <role2> <roleN>]"
          opts.separator ""
          opts.separator "Options:"

          opts.on('-v',"Increse verbosity. -vvv is max verbosity  ") do |v|
            options.verbose += 1
          end

          opts.on('-q','--quiet','Send output to a logfile, not stdout/stderr')\
          do |q|
            options.quiet = true
          end

          opts.on('-I','--init','Run FLACM continually for init (implies -q)') \
          do |d|
            options.quiet = true
            options.daemon = true
          end

          opts.on('-i','--ignore',"Stop FLACM") do |i|
            options.ignore = true
          end

          opts.on('-n','--no-ignore',"un-Stop FLACM") do |n|
            options.no_ignore = true
          end

          opts.on('-F','--force',"Force FLACM to run a role (bypass roles \n\
configuration).") do |n|
            options.force = true
          end

          opts.on('-S','--status',"Report flacm's status") do
            options.status = true
          end

          opts.on('-s SOURCE','--source SOURCE', String, 
          "Use an alternate FLACM source") do |source|
            options.source = source
          end

          opts.on('-R SOURCE','--roles-source SOURCE', String, 
          "Use an alternate FLACM roles data source") do |source|
            options.roles_source = source
          end

          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end
        end
        begin
          opts.parse!(command_args)
        rescue OptionParser::InvalidOption, OptionParser::MissingArgument \
               => error
          puts "####  " + error + "  ####"
          puts
          puts opts
          exit 1
        end
        unless command_args.empty?
          options.roles_to_run = command_args
          if options.verbose >= 3
            puts "You want to run roles: #{options.roles_to_run.join(' ')}"
          end
        end
        return options
      end
    end
  end
end
