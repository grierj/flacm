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

# Preserves all sub-modules in FLACM:: namespace.
#
module FLACM
  # Establish FLACM::Log namespace.  FLACM::Log is where FLACM
  # handles reading from and writing to FLACM logs.
  #
  module Log
    def initialize(file)
      if File.stat(file).size > 10737418240
        logfh = File.open(file, 'w')
      else
        logfh = File.open(file,'a')
      end
      @@logfile = logfh
    end
    def self.info(message)
      level = "INFO"
      FLACM::Log.message(level,message)
    end
    def self.warning(message)
      level = "WARNING"
      FLACM::Log.message(level,message)
    end
    def self.error(message)
      level = "ERROR"
      FLACM::Log.message(level,message)
    end
    def self.message(level,message)
      STDOUT.puts(level + ": " + message)
    end
  end
end
