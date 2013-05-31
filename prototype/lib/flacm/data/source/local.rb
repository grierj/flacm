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
require 'fileutils'

module FLACM
  module Data
    class Source
      module Local
        # Method for getting local files and putting them somewhere.
        #
        # Args:
        # - dir: String -- The directory to pull the files from
        #
        # Returns:
        # - nil
        #
        def self.get(dir,root)
          FLACM.debug(3, "Copying #{dir} to #{root}")
          FileUtils.cp_r(dir,root)
        end

        def self.sync(source, dest)
          FLACM::Data::Source::Rsync.local_sync(source,dest)
        end

        # Method for creating a directory with some psuedo-unique info tacked
        # on to the end.  It doesn't really defeat race conditions, but should
        # keep the system from stomping on itself even if you move to a
        # threaded architecture.
        #
        # Args:
        # - name: String -- The name of the directory (not including random
        #                   content).  Defaults to 'flacm'
        # - prefix: String -- Where to put your "root" directory if not at the
        #                     system root.
        # Returns:
        # - root_dir: String -- The directory it created.
        #
        def self.make_root(name='flacm',prefix=nil)
          random_number = rand(1000)
          dir_name = name + random_number.to_s + Time.now.to_i.to_s
          if prefix
            root_dir = prefix + '/' + dir_name
          else
            root_dir = '/tmp/' + dir_name
          end
          if File.exists?(root_dir)
            if File.directory?(root_dir)
              raise FLACM::Data::Source::Local::DirectoryError, 'Temporary \
root directory already exists!  Beware of race conditions'
            elsif File.file?(root_dir)
              File.unlink(root_dir)
            else
              raise FLACM::Data::Source::Local::DirectoryError, 'Some sort \
special file exists where we want to put your temporary root directory'
            end
          else
            FileUtils.mkdir_p(root_dir)
          end
          return root_dir
        end
        def self.clean(dir)
          FileUtils.rm_rf(dir)
        end
        class DirectoryError < RuntimeError
        end
      end
    end
  end
end
