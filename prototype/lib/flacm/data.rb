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
require 'flacm/data/exec'
require 'flacm/data/source'
require 'fileutils'

# Preserves all sub-modules in FLACM:: namespace.
#
module FLACM
  # Establish FLACM::Data namespace.  FLACM::Data is where FLACM
  # handles data of all types, including data sources, configuration files
  # as well as acting as a server or client.
  #
  module Data
    # Error Codes
    class Error < Exception
    end
    class NoBaseFile < Error
    end
    class NotWritable < Error
    end
    class NotImplemented < Error
    end
    # just a wrapper for the source module which figures stuff out
    def self.get(file, dir)
      FLACM::Data::Source.get(file, dir)
    end
    # Move a file from one place to another... more complicated then it sounds
    def self.move(oldfile, newfile)
      symlink=false
      if File.exists?(oldfile)
        if File.symlink?(oldfile)
          FLACM.debug(3,"Source file '#{oldfile}' is a symlink")
          symlink=true
          if File.exists?(newfile)
            if File.directory?(newfile)
              unless File.symlink?(newfile)
                raise FLACM::Data::NotImplemented,
    "I can't safely replace a directory with a symlink yet"
              end
            end
          end
        end
        if File.exists?(newfile)
          unless symlink
            if FileUtils.identical?(oldfile, newfile)
              FLACM.debug(3, "#{newfile} is the same as #{oldfile}")
              return nil
            end
            unless File.writable?(newfile)
              raise FLACM::Data::NotWritable, "Can't write to file: #{newfile}"
            end
          end
        else
          newdir = File.dirname(newfile)
          if File.exists?(newdir)
            if File.directory?(newdir)
              unless File.writable?(newdir)
                raise FLACM::Data::NotWritable, 
                      "Can't write to directory: #{newfile}"
              end
            else
              raise FLACM::Data::NotImplemented, 
    "Won't overwrite regular file #{newfile} to make a directory"
            end
          else
            FLACM.debug(3,"Creating directory #{newdir}")
            FileUtils.mkdir_p(newdir)
          end
        end
        if symlink
          oldtarget = String.new
          newtarget = String.new
          begin
            oldtarget = File.readlink(oldfile)
            newtarget = File.readlink(newfile)
          rescue Errno::ENOENT
          end
          unless oldtarget.eql?(newtarget)
            FLACM.debug(3,"Symlink at #{oldfile} doesn't match #{newfile}")
            if File.exists?(newfile)
              FLACM.debug(3,"Removing old symlink at #{newfile}")
              FileUtils.rm(newfile)
            end
            FLACM.debug(3,"Creating symlink of #{oldtarget} to #{newfile}")
            FileUtils.symlink(oldtarget,newfile)
          else
            FLACM.debug(3,
    "Symlink at #{oldfile} matches #{newfile}, not copying")

          end
        else
          FLACM.debug(3,"Copying #{oldfile} to #{newfile}")
          FileUtils.cp(oldfile, newfile, :preserve => true)
        end 
      end
    end
    # Append a file part to a whole file.  Call self.contains to verify that
    # file doesn't already contain an exact replica.
    #
    # Args:
    # - filepart: String -- The file that contains the snippet you want to add
    #                       to another file
    # - file: String -- The file the you want to add the snipped to.
    #
    # Returns:
    # - nil
    #
    def self.append(filepart, file)
      if File.exists?(file) and File.writable?(file) 
        FLACM.debug(3, 
    "Checking to see if #{filepart} has already been appended to #{file}")
        unless contains(filepart, file)
          FLACM.debug(3, "Injecting file part into #{file}")
          fh = File.open(file, 'a')
          fh.flock(File::LOCK_EX)
          fh.puts(File.open(filepart, 'r').readlines)
          fh.flock(File::LOCK_UN)
        end
        # TODO: This will eventually need to check and see if the user wants us
        # to create new files from parts.  If so it'll just call a Data.move
        # method.
      else
        FLACM.debug(3,"#{file} doesn't exist or cannot be written to")
        raise FLACM::Data::NoBaseFile,
              "The base file does not exist or can't be written to."
      end
    end
    # Checks to see if a file contains a particular snippet (of arbitrary size)
    # This does NOT read the whole file into memory
    #
    # Args:
    # - part: String - the name of the file that contains the part you're
    #                  looking for
    # - file: String - the name of the file that you're going to search through
    #
    def self.contains(part, whole)
      match = false
      #fh = File.open(whole, 'r') and fh_part = File.open(part, 'r')
      wholefile = File.open(whole, 'r')
      part_stripped = strip_comments(part)
      # Retain an original copy so we can rewind
      partfile = part_stripped
      part_line = partfile.shift
      wholefile.each do |line|
        if line.eql?(part_line)
          FLACM.debug(3, "Found match for line: #{part_line} in #{whole}")
          match = true
        else
          FLACM.debug(4, "No match for following lines:\n#{part_line}\n#{line}")
        end
        while match
          whole_line = wholefile.gets
          part_line = partfile.shift
          FLACM.debug(4, "Part line: #{part_line}")
          FLACM.debug(4, "Whole line: #{whole_line}")
          if part_line.nil?
            FLACM.debug(3, "Got a complete match, not inserting #{part}")
            return true
          end
          unless whole_line.eql?(part_line)
            FLACM.debug(3, "The match deviated before our part file ended")
            partfile = part_stripped
            part_line = partfile.shift
            match = false
          end
        end
      end
      return false
    end
    # A simple method for remove comments from a file for matching and 
    # potentially writing out the part file.  Comments may be useful though,
    # so who knows.
    #
    # Args:
    # file: String -- The file to open and strip, we're not taking IO streams
    #                 at this point
    # comments: String -- This is what's fed to the match method to see if you
    #                     found a comment.  Default is just "^[\s]*#"
    def self.strip_comments(file, comments="^[\s]*#")
      stripped_file = Array.new
      File.open(file, 'r').each do |line|
        unless line.match("#{comments}")
          stripped_file.push(line)
        end
      end
      return stripped_file
    end
    # A simple method for removing files we no longer want on a system
    #
    # Args:
    # - file: String -- The file to remove (full path)
    #
    # Returns:
    # - nil
    # 
    def self.remove(file)
      unless File.exists?(file)
        FLACM.debug(3, "The file #{file} is already gone, nothing to remove")
        return nil
      else
        FLACM.debug(3, "Try to remove #{file}")
        if File.file?(file)
          File.unlink(file)
        else
          FLACM.debug(2, 
    "I refuse to remove the non-file: #{file}.\n Put it in your post script.")
        end
      end
    end
  end
end
