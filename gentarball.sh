#!/bin/sh
#
#    This file is part of FLACM.
#
#    FLACM is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    FLACM is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
#
FLACM_RPM_SOURCE_DIR='/space/packages/rpms/flacm/src'

if [ -f flacm.tar.gz ];then
  rm flacm.tar.gz
fi
tar -zcf flacm.tar.gz lib init-flacm config-flacm flacm flacm.conf
if [ -d $FLACM_RPM_SOURCE_DIR ]; then
  cp flacm.tar.gz $FLACM_RPM_SOURCE_DIR
else
  scp flacm.tar.gz awacs.responsys.net:$FLACM_RPM_SOURCE_DIR
fi
