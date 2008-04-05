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
require 'net/http'

module FLACM
  module Data
    class Source
      # The module for methods dealing with getting stuff from web servers.
      #
      module HTTPS
        # Method for getting files from a web server.  Essentially a wget
        # wrapper.  This could be done in pure ruby, but wget is nice.
        #
        # Args:
        # - url: String -- where to pull the files from.  the string should
        #                  be formatted like: //<server>/<dir>/<to>/<stuff>
        # - dir: String -- where to put the files
        # - cutdirs: String -- how many sub directories to trim off.  For
        #                      instance foo.com/flacm/ROLES/admin will want
        #                      to cut 2 subdirectories off so that only "admin"
        #                      is used.
        #
        # Returns:
        # - nil
        #
        def self.get(url, dir)
          FLACM::Data::Source::HTTP.get(url, dir, 'https')
        end
      end
    end
  end
end
