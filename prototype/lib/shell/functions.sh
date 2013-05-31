# Simple commonly used shell functions for flacm support scripts to source.
#
#  This file is part of FLACM-lib.
#  
#  FLACM-lib is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  FLACM-lib is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with FLACM-lib.  If not, see <http://www.gnu.org/licenses/>.
#
# Last edit: $Date: 2008-03-19 17:25:33 -0700 (Wed, 19 Mar 2008) $

# Exit with a message and die
die() {
  echo $*
  return 1
}

# Simple search and replace for files.
#
# TODO: Replace/extend with built in FLACM variable substitution in files.
sedit()
{
  # mktemp generates secure temp files.
  temp=`mktemp`
  mktemp_return_value=$?
  if [ $# -ne 3 ]; then
    # Usage message.
    die "Usage: sedit <match> <replacement> <filename>"
  # If temp file was created successfully, do the replacement.
  elif [ $mktemp_return_value -eq 0 ]; then
    sed -e "s#$1#$2#g" $3 > $temp
    # If a replacement happened.
    if [ $? -eq 0 ]; then
      # Fix the mode.
      mode=`stat -c %a $3`
      if [ $? -eq 0 ]; then
        chmod $mode $temp $3
      fi
      # Fix the owner.
      owner=`stat -c %U:%G $3`
      if [ $? -eq 0 ]; then
        chown $owner $temp $3
      fi
      # Fix the date of the modified file.
      date=`date -r $3`
      if [ $? -eq 0 ]; then
        touch -d "$date" $temp
      fi
      # Overwrite the original.
      mv $temp $3
      if [ $? -ne 0 ]; then
        die "failed to move $temp to $3"
      fi
    else
      die "Could not run sed"
    fi
  else
    die "Could not run mktemp"
  fi
}

# Add RPM if it doesn't exist already.
#
#
# Usage: add_rpms <rpm> [<rpm2> <rpm3>..<rpmN>
add_rpms() {
  if [ $# -lt 1 ]; then
    die "Usage: add_rpms <rpmname> [<rpm2> <rpm3>..<rpmN>]"
  else
    for package in $*; do
      rpm -qi $package >/dev/null 2>&1
      if [ $? -ne 0 ]; then
        yum -y install $package
      fi
    done
  fi
  return 0
}

# Assure that a service is enabled at boot.
#
#
ensure_enabled() {
  if [ $# -lt 1 ]; then
    die "Usage: ensure_enabled <service> [<service2> <service3>..<serviceN>]"
  else
    for service in $*; do
      if [ -e /etc/init.d/$service ]; then
        if [ ! -x /etc/init.d/$service ]; then
          chmod 755 /etc/init.d/$service
        fi
      fi
      chkconfig $service
      if [ $? -ne 0 ]; then
        chkconfig $service on
      fi
    done
  fi
  return 0
}

# Assure that a service is running.
#
#
ensure_running() {
  if [ $# -lt 1 ]; then
    die "Usage: ensure_running <service> [<service2> <service3>..<serviceN>]"
  else
    for service in $*; do
      running=`service $service status >/dev/null 2>&1`
      if [ $? -ne 0 ]; then
        service $service start
      fi
    done
  fi
  return 0
}

# Assure that a service is both enabled and running.
#
#
ensure_on() {
  if [ $# -lt 1 ]; then
    die "Usage: ensure_on <service> [<service2> <service3>..<serviceN>]"
  else
    ensure_enabled $*
    ensure_running $*
  fi
  return 0
}

# Assure that a service is disabled at boot.
#
#
ensure_disabled() {
  if [ $# -lt 1 ]; then
    die "Usage: ensure_disabled <service> [<service2> <service3>..<serviceN>]"
  else
    for service in $*; do
      chkconfig $service
      if [ $? -eq 0 ]; then
        chkconfig $service off
      fi
    done
  fi
  return 0
}

# Assure that a service is stopped.
#
#
ensure_stopped() {
  if [ $# -lt 1 ]; then
    die "Usage: ensure_stopped <service> [<service2> <service3>..<serviceN>]"
  else
    for service in $*; do
      stopped=`service $service status >/dev/null 2>&1`
      if [ $? -eq 0 ]; then
        service $service stop
      fi
    done
  fi
  return 0
}

# Assure that a service is both disabled and not running.
#
#
ensure_off() {
  if [ $# -lt 1 ]; then
    die "Usage: ensure_off <service> [<service2> <service3>..<serviceN>]"
  else
    ensure_disabled $*
    ensure_stopped $*
  fi
  return 0
}

# Remove an RPM if it is installed.
#
#
# Usage: remove_rpms <rpm> [<rpm2> <rpm3>..<rpmN>
remove_rpms() {
  if [ $# -lt 1 ]; then
    die "Usage: remove_rpms <rpmname> [<rpm2> <rpm3>..<rpmN>]"
  else
    for package in $*; do
      rpm -qi $package >/dev/null 2>&1
      if [ $? -eq 0 ]; then
        yum -y remove $package
      fi
    done
  fi
  return 0
}

# Change permissions on file(s) if it(they) exist.
#
#
# Usage: safe_chmod <permissions> <file|spec> [<file|spec2> <file|spec3..N>]
# BUGS: No option passing supported.
safe_chmod() {
  if [ $# -lt 2 ]; then
    die "Usage: safe_chmod <permissions> <file|spec> [<file|spec2> <file|spec3..N>]"
  else
    permissions=$1
    shift
    for file in $*; do
      if [ -e $file ]; then
        chmod $permissions $file
      fi
    done
  fi
  return 0
}

# Change ownership on file(s) if it(they) exist.
#
#
# Usage: safe_chown <owner> <file|spec> [<file|spec2> <file|spec3..N>]
# BUGS: No option passing supported.
safe_chown() {
  if [ $# -lt 2 ]; then
    die "Usage: safe_chown <owner> <file|spec> [<file|spec2> <file|spec3..N>]"
  else
    owner=$1
    shift
    for file in $*; do
      if [ -e $file ]; then
        chown $owner $file
      fi
    done
  fi
  return 0
}

# Change permissions recursively on directories if they exist.
#
#
# Usage: safe_chmod_r <permissions> <dir|spec> [<dir|spec2> <dir|spec3..N>]
# BUGS: No option passing supported.
safe_chmod_r() {
  if [ $# -lt 2 ]; then
    die "Usage: safe_chmod_r <permissions> <dir|spec> [<dir|spec2> <dir|spec3..N>]"
  else
    permissions=$1
    shift
    for dir in $*; do
      if [ -e $dir ]; then
        chmod -R $permissions $dir
      fi
    done
  fi
  return 0
}

# Change ownership recursively on file(s) if it(they) exist.
#
#
# Usage: safe_chown <owner> <dir|spec> [<dir|spec2> <dir|spec3..N>]
# BUGS: No option passing supported.
safe_chown_r() {
  if [ $# -lt 2 ]; then
    die "Usage: safe_chown_r <owner> <dir|spec> [<dir|spec2> <dir|spec3..N>]"
  else
    owner=$1
    shift
    for dir in $*; do
      if [ -e $dir ]; then
        chown -R $owner $dir
      fi
    done
  fi
  return 0
}


