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

require "flacm"

module FLACM
  module Roles
    # Establish the FLACM::Roles::Generic namespace.  These are the methods
    # that all other roles based modules will use.  They should be written so
    # that specific roles will have an easy time inserting role-sensitive data.
    #
    class Generic
      attr_reader :flacm_url, :file_and_type
      # Error codes
      class Error < Exception
      end
      class NoScriptError < Error
      end
      class NoTempRootError < Error
      end
      # A new generic role.  This role does all it's role-like things, but
      # are no hard-coded paths nor script names.  We want all that to be
      # determined by the non-generic roles
      #
      # Args:
      # - flacm_url: String -- The URL to FLACM root
      # - server: String -- The server that we're concerned with
      # Returns:
      # - FLACM::Roles::Generic object
      #
      def initialize(flacm_url,part_as_whole)
        @default_file_type = 'whole'
        @flacm_url = flacm_url
        @part_as_whole = part_as_whole
        # Data structures for directory traversal and file reconciliation
        @traverse_me = Array.new
        @file_and_type = Hash.new
        FLACM.debug(3, "Creating new data source")
        @data_source = FLACM::Data::Source.new(@flacm_url)
        FLACM.debug(3, "Creating false root")
        @my_root = FLACM::Data::Source::Local.make_root
        FLACM.debug(3, "Putting data in false root")
        @data_source.put_in(@my_root)
        FLACM.debug(3, "Scanning false root")
        search_dir(@my_root+'/'+File.basename(@flacm_url)+'/root')
        return self
      end
      
      # Method for running a script, bascially just pops off to
      # FLACM::Data::Exec and mucks around there, but the user should be
      # writing around roles, not data.
      #
      # Args:
      # - script: String -- The script to run, hopefully the full path to the
      #                     script
      # - args: String -- Any arguments you want to push to the script.  Not
      #                   required
      # Returns:
      # - boolean
      #
      def run_script(script,args=String.new,exit_on_fail=true)
        full_script = String.new
        if File.exists?(script)
          full_script = script + " " + args
        elsif File.exists?(@my_root+'/scripts/'+script)
          full_script = @my_root+'/scripts/'+script + " " + args
        else
          raise FLACM::Roles::Generic::NoScriptError, 'No script found where I \
expected it'
        end
        FLACM::Data::Exec.do(full_script,exit_on_fail)
      end

      # Wrapper methods for dealing with part, whole, and diff files.  This
      # just keeps the end user writing against his role and out of the data
      # area.
      def part(partfile, file)
        begin
          FLACM::Data.append(partfile, file)
        rescue  FLACM::Data::NoBaseFile
          if @part_as_whole
            self.whole(partfile, file)
          else
            FLACM::Log.error("No whole file to write to")
          end
        end
      end
      
      def whole(wholefile, file)
        FLACM::Data.move(wholefile,file)
      end

      def diff(patchfile, file)
        FLACM::Data.patch(patchfile, file)
      end

      def remove(unused, file)
        # Get rid of the fixroot bit
        FLACM::Data.remove(file)
        dirpart = String.new
        finaldir = Array.new
        patharray = file.split('/')
        until dirpart.eql?('root')
          dirpart = patharray.pop
          finaldir.unshift(dirpart)
        end
        finaldir.shift
        file = '/' + finaldir.join('/')
        # Now we have the local path, remove it too
        FLACM::Data.remove(file)
      end

      # Alias clean-up for the same reason
      def cleanup(dir=@my_root)
        FLACM::Data::Source::Local.clean(dir)
      end

      # Alias for syncing stuff after fix
      def sync(source,dest)
        FLACM::Data::Source::Local.sync(source,dest)
      end

      # Method for building the file list.  It traverses all directories in
      # the supplied root and looks for regular files.  When it finds a regular
      # file it tries to determine it's "type" by file extension and throws
      # file and type into a has.  .whole types overwrite .part and .diff and
      # cause a warning to be logged.
      # When the method finds a directory it adds it to an array of directories
      # to check and follows a first-in first-out setup (push and shift on the 
      # array.
      # TODO: This method is self referencing so there needs to be testing to 
      # make sure it won't loop... possibly dupe checking on the array.
      #
      # Args:
      # - dir: String -- The directory to search through.
      # - subrole: Boolean -- Overwrite all entries in the file hash without
      #                       checking or complaining
      # Returns:
      # - nil
      #
      def search_dir(dir,subrole=false)
        file_exts = ['whole', 'part', 'remove']
        FLACM.debug(3, "Looking in dir #{dir}")
        Dir.foreach(dir) do |file|
          FLACM.debug(3, "Looking at file #{file}")
          unless file.eql?('.') or file.eql?('..') or file.eql?('.svn')
            fullpath = dir + '/' + file
            FLACM.debug(3, "Taking a closer look at file #{file}")
            if File.symlink?(fullpath) or File.file?(fullpath)
              FLACM.debug(3, "Found regular file #{file}")
              split_name = file.split('.')
              if split_name[0].empty?
                split_name.shift
                split_name[0] = '.'+split_name[0]
              end
              if split_name.length > 1
                filename = dir + '/' + split_name[0..-2].join('.')
                type = split_name[-1]
              else
                filename = dir + '/' + split_name.to_s
                type = ''
              end
              file_ext_match = false
              file_exts.each do |ext|
                if type.eql?(ext)
                  FLACM.debug(4, "Extension matches FLACM type #{ext}")
                  file_ext_match = true
                end
              end
              unless file_ext_match
                unless type.empty?
                  filename = filename + '.' + type
                end
                type = ''
              end
              FLACM.debug(3, "Assuming filename is #{filename}")
              FLACM.debug(3, "Assuming type is: #{type}")
              unless @file_and_type.has_key?(filename)
                @file_and_type[filename] = type
              else
                if  subrole
                  @file_and_type[filename] = type
                else
                  unless @file_and_type[filename].eql?('whole')
                    FLACM::Log.warning("Whole file overwriting entry for \
#{filename} with type #{@file_and_type[filename]}")
                    @file_and_type[filename] = type
                  end
                end
              end
            elsif File.directory?(fullpath)
              FLACM.debug(3, "Found directory #{file}")
              @traverse_me.push(fullpath)
              FLACM.debug(3, "My directory list is now: #{@traverse_me}")
            else
              FLACM.debug(3, "Skipping unknown file #{file}")
            end
          end
        end
        unless @traverse_me.empty?
          next_dir = @traverse_me.shift
          FLACM.debug(3, "Checking the next directory #{next_dir}")
          search_dir(next_dir)
        end
        FLACM.debug(3, "No more directories to search. Leaving #{dir}")
        FLACM.debug(3, "File list is #{@file_and_type.to_s}")
      end
      # A generic "run" script for roles that don't need fancy stuff
      #
      # Args:
      # - role: The role we're running
      # - root: The root of the copied data source
      #
      # Returns:
      # - nil
      #
      def run(role=@role, root=@my_root)
        begin
          FLACM.debug(3,"Entering FLACM::Roles::#{role.capitalize}.run")
          begin
            run_script("#{root}/#{role}/scripts/pre")
          rescue FLACM::Roles::Generic::NoScriptError
            FLACM::Log.error("Didn't find a pre-install script at \
#{root}/#{role}/scripts/pre")
          end
          # Run fix-it
          fix(root,role)
          # Remember your rsync syntax and put a trailing slash at the end of
          # your source directory
          sync("#{@fixroot}/#{role}/root/",'/')
          begin
            FLACM.debug(3,"Running Post-Installation script: \
#{root}/#{role}/scripts/post")
            run_script("#{root}/#{role}/scripts/post", String.new, false)
          rescue FLACM::Roles::Generic::NoScriptError
            FLACM::Log.error("Didn't find a post-install script at \
#{root}/#{role}/scripts/post")
          end
        ensure
          FLACM.debug(3,"Deleting #{@my_root}")
          cleanup
          cleanup(@fixroot)
          FLACM.debug(3,"Leaving FLACM::Roles::#{role.capitalize}.run")
        end
      end
      def self.find(source)
        dir = String.new
        dir = FLACM::Data::Source::Local.make_root
        raise NoTempRootError if dir.empty?
        data_source = FLACM::Data::Source.new(source)
        data_source.get(dir)
        file_path = File.basename(data_source.location)
        begin
          roles = YAML.load_file("#{dir}/#{file_path}")
        rescue NoMethodError
          # Support for old versions of YAML, the above is cleaner though.
          roles = File.open( "#{dir}/#{file_path}" ) { |line| \
            YAML::load(line) }
        end
        data_source.clean(dir)
        return roles
      end
      # A generic way of splitting a role from a list of hosts in YAML.
      def self.parse(source_yaml, my_host=Socket.gethostname)
        my_roles = Array.new 
        source_yaml.each_key do |role|
          source_yaml[role].each do |host|
            if host == my_host
              my_roles.push(role)
            end
          end
        end
        return my_roles
      end
      # Fix is a special thing, run fix out of here so it's contained on its
      # own.
      def fix(flacmroot=@my_root,role=@role)
        full_role=role
        role_array=role.split('+')
        if role_array.length > 1
          role = role_array[0]
        end
        @fixroot = String.new
        @fixroot = FLACM::Data::Source::Local.make_root('fix')
        @file_and_type.each_pair do |filename, type|
          sub_out = "#{flacmroot}/#{role}/root"
          sub_in = "#{@fixroot}/#{role}/root"
          local_file = filename.sub(sub_out,'')
          fix_file = filename.sub(sub_out,sub_in)
          extension = String.new
          extension = ".#{type}"
          retried_eval = false
          begin
            FLACM.debug(3, "Copying local file, \"#{local_file}\" to \
fix-root")
            begin
              whole(local_file,fix_file)
            rescue Errno::ENOENT
              FLACM.debug(3, "Didn't find local file #{local_file}")
            end
            type_method = "#{type}('#{filename}#{extension}', '#{fix_file}')"
            FLACM.debug(3,"Trying to run #{type_method}")
            eval type_method
          rescue NameError,SyntaxError
            if retried_eval
              raise
            else
              extension = String.new if type.empty?
              fix_file = fix_file + extension
              type = 'whole'
              retried_eval=true
              retry
            end
          end
        end
        begin
          FileUtils.chown_R('root','root',"#{@fixroot}/#{role}/root")
        # Usually an empty fileset
        rescue Errno::ENOENT
          FLACM::Log.warning("No files found for the role \"#{role}\"") 
          FileUtils.mkdir_p "#{@fixroot}/#{role}/root"
        end
        FLACM.debug(3,"Switching directories to: #{@fixroot}/#{role}/root")
        Dir.chdir("#{@fixroot}/#{role}/root")
        begin
          run_script("#{flacmroot}/#{role}/scripts/fix", "#{full_role} \
#{@fixroot}/#{role}/root")
        rescue FLACM::Roles::Generic::NoScriptError
          FLACM::Log.error("No fix-it script at: \
#{flacmroot}/#{role}/scripts/fix")
        end
        FLACM.debug(3,"Switching directories to: /opt/flacm")
        Dir.chdir('/opt/flacm/')
      end
    end
  end
end
