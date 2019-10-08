#!/usr/bin/env bash
#
# Copyright 2019 Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

################################################################################
#
# utility commands for components using the runner plugin
# this script can be sourced by the
#   lib/sow.sh   ( source "$SOW/plugins/runner/sow.sh" )
# script of a greenhouse or crop to offer these commands
# for the sow command used with the actual product.
#

HELP_log()
{
  echo "log [-f] [<$nCOMPONENT> [<instance>]]:log for runner execution"
  echo " -f:use tail -f instead of cat"
  cat <<EOF 

The runner starts commands as background processes. The log containing
stdout and stderr of the executed command is stored in the plugin
instance's gen folder.

This command can be used to show (or tail) this log just using
the sow command.
EOF
}

CMD_log()
{
  declare -A params=( [f]= )
  declare -A opts

  OPT_parse_options params opts "$@"
  shift $(( _cnt - 1 ))

  local comp
  if [ $# -eq 0 ]; then
    resolveComponents comp .
  else
    resolveComponents comp "$1"
  fi
  
  for c in "${comp[@]}"; do
    setupPluginsFile $c
    if [ ! -f "$PLUGINSFILE" ]; then
      fail "no plugins executed for $nCOMPONENT $c"
    fi
    LIST="$(cat "$PLUGINSFILE")"

    local instance
    local msg
    if [ -z "$2" ]; then
      verbose "determine runner"
      local current=( )
      local name

      getValueList current current LIST
      for i in "${current[@]}"; do
        getValue name "plugins[\"$i\"].name" LIST
        if [ "$name" == runner ]; then
          if [ -n "$instance" ]; then
            header_message msg hint
            hint " - $i"
          else
            msg="There are multiple runner instances in $nCOMPONENT $c
 - $i"
            instance="$i"
          fi
        fi
      done
      if [ -z "$instance" ]; then
        fail "no runner instance found in $nCOMPONENT $c"
      fi
      if [ -z "$msg" ]; then
        exit 0
      fi
    else
      getValue name "plugins[\"$2\"].name"  LIST
      if [ -z "$name" ]; then
        fail "plugin instance $2 not found in $nCOMPONENT $c"
      fi
      if [ "$name" != runner ]; then
        fail "plugin instance $2 in $nCOMPONENT $c is no runner"
      fi
      instance="$2"
    fi

    if [ ! -f "$GEN/$c/$instance/log" ]; then
      fail "no log file for runner $2 found in $nCOMPONENT $c"
    fi
    info "log file for runner $instance in $nCOMPONENT $c"
    if [ "${opts[f]+set}" ]; then
      tail -f "$GEN/$c/$instance/log"
    else
      cat "$GEN/$c/$instance/log"
    fi
  done
}

