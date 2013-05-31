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
    class Host < Generic
      def initialize(flacm_url, host, part_as_whole=false)
        @flacm_url = flacm_url
        @host = host
        @host_url = @flacm_url + "/HOSTS/" + @host
        begin
          super(@host_url, part_as_whole)
        rescue Errno::ENOENT,FLACM::Data::Exec::FailedScriptError
          cleanup
          raise
        end
      end
      def run(role=@host, root=@my_root)
        super(@host, @my_root)
      end
      def find(source)
        super(source)
      end
      def parse(source_yaml, my_hostname=String.new)
        if my_hostname.empty?
          super(source_yaml)
        else
          super(source_yaml, my_hostname)
        end
      end
    end
  end
end
