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
require 'flacm/data/source/local'
require 'flacm/data/source/nfs'
require 'flacm/data/source/http'
require 'flacm/data/source/https'
require 'flacm/data/source/rsync'

module FLACM
  module Data
    # Establish the FLACM::Data::Sources name space.  This is where FLACM
    # handles reading from and writing to data sources.  This could be a
    # file system, a data base, or a flat file.
    #
    class Source
      attr_reader :location
      def initialize(url)
        @type, @location = self.parse(url)
        return self
      end 
      # Method for parsing out what sort of data source we're supposed to be
      # talking to. 
      #
      # Args:
      # - url: String -- A url of a data source.  For example: 
      #                 http://foo.com/flacm/os
      #                 local:/flacm/roles
      #                 mysql://foo.com/Flacm.domain
      # Returns:
      # - type: String -- The type of data source, http, rsync, local,  etc
      def parse(url)
        # Insanely simple for right now but I want it to be extendible
        type, location = url.split(':')
        return [type, location]
      end

      # Method for getting data from the objects data source and putting it in
      # a specified directory
      def get(rootdir, type=@type, location=@location)
        # Dynamically name a method string.  There might be a better way to
        # do this, but I couldn't figure one out
        try = 1
        # turn "local" to "Local" to match normal Class/Module style naming
        type.capitalize!
        FLACM.debug(3, "Figuring out right source module")
        begin
          FLACM.debug(3, "We're on try number #{try}")
          get_method = "FLACM::Data::Source::#{type}"
          FLACM.debug(3, "Trying module #{get_method}")
          get_class = eval(get_method)
          # Check to see that we've go a real module it'll throw a NameError
          # if we don't.
          get_class.object_id
        rescue NameError
          # For things like HTTP
          if try < 2
            FLACM.debug(3, "Trying all upcase")
            type.upcase!
            # try.next didn't work... hmmm.
            try = try + 1
            retry
          else
            raise
          end
        end

        FLACM.debug(3, "My root directory is going to be #{rootdir}")
        get_class.get(location, rootdir)
      end
      alias put_in get

      def clean(dir)
        FLACM::Data::Source::Local.clean(dir)
      end
    end
  end
end
