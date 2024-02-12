#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Gardener contributors
#
# SPDX-License-Identifier: Apache-2.0


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
      declare -A runners

      getSelectedJsonMapEntries runners plugins '.name=="runner"' LIST
      case ${#runners[@]} in
        0) fail "no runner instance found in $nCOMPONENT $c";;
        1) instance="${!runners[@]}";;
        *) hint "There are multiple runner instances in $nCOMPONENT $c"
           for i in "${!runners[@]}"; do
             hint "- $i"
           done
           exit 0;;
      esac
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

