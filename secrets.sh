#!/usr/bin/env bash
#/ Usage: secrets.sh <operation> [<key> [<value]]
#/
#/ Simple secrets manager in bash using no encryption
#/
#/   Store a secret:    secrets.sh set my_secret_key my_secret
#/            ...or:    secrets.sh set my_secret_key
#/   Retrieve a secret: secrets.sh get my_secret_key
#/   Forget a secret:   secrets.sh del my_secret_key
#/   List all secrets:  secrets.sh list
#/   Dump database:     secrets.sh dump
#/
# Copyright (c) 2018 Jordan Webb
#  - urlencode by Brian K. White
#  - urldecode by Chris Down
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e
set -o pipefail

usage()
{
  grep "^#/" <"$0" | cut -c4-
}

#/ By default, the file $HOME/.secrets will be used to store secrets. If
#/ you prefer, set the SECRETS_PATH in your environment to a different path.
#/
SECRETS_PATH=${SECRETS_PATH:-"$HOME/.secrets"}

if [ -z "$COLUMNS" ] ; then
  if [ -t 1 ] ; then
    COLUMNS=$(tput cols)
  else
    COLUMNS=72
  fi
fi

SECRETS_LIST_FORMAT=${SECRETS_LIST_FORMAT:-"%-$((COLUMNS - 26))s | %s"}
SECRETS_DATE_FORMAT=${SECRETS_DATE_FORMAT:-"%F %I:%M%p %Z"}

require_args()
{
  local operation=$1 want=$2 have=$3
  if [ "$want" -ne "$have" ] ; then
    echo "ERROR: incorrect number of arguments for '$operation'" >&2
    exit 1
  fi
}

urlencode()
{
  local LANG=C i c e=''
  for ((i=0;i<${#1};i++)) ; do
    c=${1:$i:1}
    [[ "$c" =~ [a-zA-Z0-9\.\~\_\-] ]] || printf -v c '%%%02X' "'$c"
    e+="$c"
  done
  echo "$e"
}

urldecode()
{
  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\\x}"
}

read_secrets()
{
  if [ ! -e "$SECRETS_PATH" ] ; then
    touch "$SECRETS_PATH"
  fi
  cat "$SECRETS_PATH"
}

write_secrets()
{
  truncate "$SECRETS_PATH" --size 0
  while read line
  do
    echo "$line" >> "$SECRETS_PATH"
  done
}

list_secrets()
{
  local this_key this_date this_value
  while read this_key this_date this_value
  do
    this_key=$(urldecode "$this_key")
    printf "$SECRETS_LIST_FORMAT\n" "$this_key" "$(date +"$SECRETS_DATE_FORMAT" --date="@$this_date")"
  done
}

extract_secret()
{
  local key=$1 this_key this_date this_value
  while read this_key this_date this_value
  do
    this_key=$(urldecode "$this_key")
    this_value=$(urldecode "$this_value")
    if [ "$this_key" = "$key" ] ; then
      printf "%s\n" "$this_value"
      break
    fi
  done
}

filter_secret()
{
  local key=$1 this_key this_date this_value
  while read this_key this_date this_value
  do
    if [ -z "$this_key" ] ; then
      break
    fi

    local decoded_key=$(urldecode "$this_key")
    if [ "$decoded_key" != "$key" ] ; then
      printf "%q %q %q\n" "$this_key" "$this_date" "$this_value"
    fi
  done
}

case $1 in
  help|--help|usage|--usage|'')
    usage
    exit 0
    ;;
  del)
    require_args "$1" "$#" 2
    read_secrets | filter_secret "$2" | write_secrets
    ;;
  set)
    if [ "$#" = "2" ] ; then
      stty -echo ; trap "stty echo" EXIT
      read -p "Value: " value
      echo ; stty echo ; trap - EXIT

      if [ -z "$value" ] ; then
        echo "ERROR: cowardly refusing to set an empty value" >&2
        exit 1
      fi
    elif [ "$#" = "3" ] ; then
      value=$3
    else
      require_args "$1" "$#" 3
    fi
    read_secrets | (
      filter_secret "$2"
      printf "%q %q %q\n" "$(urlencode "$2")" "$(date '+%s')" "$(urlencode "$value")"
    ) | write_secrets
    ;;
  get)
    require_args "$1" "$#" 2
    read_secrets | extract_secret "$2"
    ;;
  list)
    require_args "$1" "$#" 1
    read_secrets | list_secrets | sort
    ;;
  dump)
    require_args "$1" "$#" 1
    read_secrets
    ;;
  *)
    echo "ERROR: operation must be 'set', 'get', 'list' or 'dump'" >&2
    usage
    exit 1
    ;;
esac

#/
#/ For more information, see https://github.com/jordemort/secrets.sh
