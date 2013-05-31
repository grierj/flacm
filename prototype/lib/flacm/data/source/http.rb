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
      module HTTP
        # Method for getting files from a web server.  Essentially a wget
        # wrapper.  This could be done in pure ruby, but wget is nice.
        #
        # Args:
        # - url: String -- where to pull the files from.  the string should
        #                  be formatted like: //<server>/<dir>/<to>/<stuff>
        # - dir: String -- where to put the files
        #
        # Returns:
        # - nil
        #
        def self.get(url, dir, prefix='http')
          url.sub!(/^\/\/([^\/]*)/,'\1')
          dir_url = url + '/'
          wget_url = dir_url
          retried = false
          if wget_url =~ /\w\+\w/
            cutdirs=4
          else
            cutdirs=2
          end
          begin
            # Check to see that the URL is valid first
            FLACM::Data::Exec.do("wget --spider --quiet --no-check-certificate  #{prefix}://#{wget_url}")
            # Using wget in a way that acts like rsync
            FLACM::Data::Exec.do("wget -r -nH -l 20 --quiet --cut-dirs=#{cutdirs} -R index.htm\* -X .svn -P #{dir} --no-check-certificate --no-parent #{prefix}://#{wget_url}")
            # Clean up the useless index.html?C=blah nonsense
            FLACM::Data::Exec.do("find #{dir} -name \"*C=[DMNS];O=[AD]\"")
            # Scripts have to be executable, or they fail and bring down FLACM
            unless retried
              chmod_dir=url.split('/')[-1]
              FileUtils.chmod_R(755,"#{dir}/#{chmod_dir}/scripts/")
            end
          rescue Errno::ENOENT,FLACM::Data::Exec::FailedScriptError
            unless retried
              wget_url=url
              retried = true
              retry
            else
              raise
            end
          end
        end
      end
    end
  end
end
