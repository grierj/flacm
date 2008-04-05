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

module FLACM
  module Data
    # Establish the FLACM::Data::Exec name space.  This is where FLACM handles
    # the running of scripts and parsing output (if any).
    #
    module Exec
      class Error < Exception
      end
      class FailedScriptError < Error
      end
      # More checking can go in here later, but for now this is a simple start
      def self.do(command,exit_on_fail=true)
        FLACM.debug(3,"Executing: #{command}")
        proc_handle = IO.popen(command)
        proc_handle.each do |output|
          FLACM.debug(3,"Command Output: #{output}")
        end
        proc_handle.close
        unless $?.exitstatus.zero?
          if exit_on_fail
            raise FLACM::Data::Exec::FailedScriptError
          else
            FLACM::Log.error("\"#{command}\" exited with a non-zero status")
          end
        end
      end
    end
  end
end
