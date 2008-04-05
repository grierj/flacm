#!/usr/bin/ruby -w
# Skeleton Class/Module structure for FLACM (FLACM).
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

# You should set up your library in your wrapper script... uncomment below
# if you need to
#$:.push('/opt/lib/ruby')
# Development location for library
#$:.push('/svn/ops/lib/ruby')

# Require sub-classes
require 'flacm/config'
require 'flacm/data'
require 'flacm/log'
require 'flacm/roles'

# Standard ruby modules
require 'socket'

# Set up FLACM:: namespace.
module FLACM
  # Debug level is 0, no debugging output.  Debug levels are as follows:
  # 1 = important messages
  # 2 = informative messages
  # 3 = chatter
  def self.debug_level(level)
    @@debug_level = level.to_i
  end

  # Some core exception
  class FlacmError < Exception
  end
  class LockFileException < FlacmError
  end

  # Print out debugging messages if the debug_level is defined above
  # the given level.
  #
  # Args:
  # - level: Fixnum -- The debugging level at which to display the message.
  # - message: String -- The message to display.
  # Returns:
  # - nil
  def self.debug(level, message)
    if @@debug_level >= level
      STDOUT.puts message
    end
    return nil
  end
  
  # Check to see if it's time to "reboot" or refresh the running flacm
  # instance.  If it is, write out the reboot file and next cycle flacm will
  # exit and everything will revert to flacm bootstrap
  #
  # Args:
  # - interval: Fixnum -- The time (in hours) at which to reboot FLACM
  # - rebootfile: String -- Where to look for or place the reboot file.  This is
  #                         the file whose existence or non-existence controls
  #                         whether or not FLACM reboots
  #
  # Returns:
  # - nil
  def self.reboot(interval, rebootfile, statedir)
    # We obviously need to reboot if the reboot file is there, don't bother
    # mucking around, just exit
    if File.exists?(rebootfile)
      File.unlink(rebootfile)
      exit 1
    end
    # We asked our users for time in hours make it seconds to keep things
    interval = interval*3600
    startfile = "#{statedir}/.starttime"
    if File.exists?(startfile)
      starttime = File.stat(startfile).mtime.to_i
      if Time.now.to_i > starttime+interval
        File.new(rebootfile, 'w').close
        File.unlink(startfile)
      end
    else
      unless File.exists?(statedir)
        FileUtils.mkdir_p(statedir) unless File.directory?(statedir)
      end
      File.new(startfile, 'w').close
    end
    return nil
  end

  # A method to tell flacm to stop doing stuff.  In this case we just touch
  # the ignore file
  def self.stop(ignore_file)
    FileUtils.touch(ignore_file)
  end

  # A method to get flacm going again.  In this case we remove the ignore
  # file
  def self.start(ignore_file)
    if File.exists?(ignore_file)
      File.unlink(ignore_file)
    end
  end

  # A method to report the status of flacm
  def self.status(ignore_file,quiet=false)
    running=false
    ignored=false
    configuring=false
    initializing=false
    # TODO: This needs to be replaced with something that actually reads proc
    process_list = IO.popen('ps -ef')
    process_list.each do |process|
      proc_array = process.split(/\s+/)
      next if proc_array[1].eql?(Process.pid.to_s)
      process_name = proc_array[7..-1].join(' ')
      if process_name =~ /flacm/
        if process_name =~ /init-flacm/
          initializing=true
        elsif process_name =~ /config-flacm/
          configuring=true
        elsif process_name =~ /flacm/
          running=true
          if File.exists?(ignore_file)
            ignored=true
          end
        end
      end
    end
    if running
      if ignored
        puts "FLACM is running, but not active" unless quiet
        exit 2
      else
        puts "FLACM is running" unless quiet
        exit 0
      end
    elsif configuring
      puts "FLACM is on the configuration step" unless quiet
      exit 3
    elsif initializing
      puts "FLACM is on the initialization step" unless quiet
      exit 4
    else
      puts "FLACM is not running" unless quiet
      exit 1
    end
  end

  # A module for robustly gathering host info about the host that FLACM is
  # running on.
  class HostInfo
    attr_reader :os, :distro, :version, :domain, :host, :rawhost, :fqdn
    def initialize
      @rawhost = Socket.gethostname
      @fqdn = @rawhost
      @os, @distro, @version = self.get_os
      @domain = self.get_domain
      @host = self.get_host
    end
    # Method for determining the OS and distribution or version of that
    # host.  It returns an array with the OS, the distribution and the Version
    # of the OS.  This method takes it's best guess and will probably have to
    # be broken out into it's own library at some point with signarture and
    # whatnot.  But for now it does Solairs and Redhat derived Linux.
    #
    # On solaris the distro is the same as the version
    #
    # On linux the version is the kernel major, minor, and bugfix numbers. For
    # instance redhat 4/centos 4 will always have a version of 2.6.9
    #
    # Args:
    # - None
    #
    # Returns:
    # - Array -- A three value array with the OS, Distro, Version
    def get_os
      os = `uname -s`.chomp.downcase
      version = `uname -r`.chomp.downcase
      distro = 'generic'
      if os =~ /linux/
        version = version.split('-')[0]
        release_files = Dir.glob("/etc/*-release")
        if release_files.length.eql?(1)
          distro = release_files[0].split('-')[0].split('/')[2]
        else
          release_files.each do |filename|
            if release_files[0].split('-')[0] =~ /redhat/
              distro = 'redhat'
            end
          end
        end 
      elsif os =~ /sunos/
        version = version.split('.')[1]
        distro = version
      end
      return [os, distro, version]
    end
    # Method for determining the domain of the current host.  Domains in
    # flacm are a bit touchy.  Eventually there'll be some sort of lookup
    # method since this would be close to impossible to retrofit into a
    # running environment.  When starting from scratch though a subdomain
    # is a great way to split off domains.  For now we look for:
    # foo.sub.domain.com
    # 
    # Where "foo" is the host and "sub" is the domain.
    #
    # This method is a bit generic.  It's going to look for an FQDN of three
    # or more.  If 3 then it lops off the first field and returns the rest.
    # If more it lops off the first field and returns all but the last two
    # fields.
    #
    # Args:
    # - None
    #
    # Returns:
    # - String -- This server's FLACM domain.
    #
    def get_domain
      fqdn = @rawhost
      fqdn_split = fqdn.split('.')
      fqdn_len = fqdn_split.length
      if fqdn_len <= 2
        host = String.new
        h_split = String.new
        if @os =~ /linux/
          host = `hostname --fqdn`.chomp.downcase
          h_split = host.split('.')
        else
          host = Socket.gethostbyname(Socket.gethostname)
          h_split = host[0].split('.')
        end
        h_len = h_split.length
        if h_len <= 2
          raise RuntimeError, "Your domain is not parsable"
        end
        fqdn = host
        @fqdn = fqdn
        fqdn_split = h_split
        fqdn_len = h_len
      end
      if fqdn_len.eql?(3)
        domain = fqdn_split[-2..-1].join('.')
      elsif fqdn_len >= 4
        domain = fqdn_split[1..-3].join('.')
      else
        raise RuntimeError, "Your domain is not parsable"
      end
    end

    # Method for determining the short host name of a system
    # 
    # Args:
    # - None
    #
    # Returns:
    # - String -- The short hostname of the server (i.e. foo if foo.bar.com).
    def get_host
      hostname = @rawhost
      h_split = hostname.split('.')
      h_len = h_split.length
      if h_len.eql?(1)
        return hostname
      # Less then three means we don't have a FQDN
      elsif h_len >= 3
        return h_split[0]
      end
      return hostname
    end
  end
end
