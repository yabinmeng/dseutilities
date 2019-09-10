#!/bin/bash

#
# NOTE: this script was designed for in-place changing (lowering down) C* num_tokens values
#       - the old and new num_tokens values must be both the expotential of 2
#       - the new value needs to be less than the old value
#       e.g. 64 to 32  (divider_number is 2), or
#            64 to 8   (divider_number is 8)
#


num_tokens=$1
divider=1

if [[ $# -eq 2 ]]; then
  divider=$2

  if [[ $2 -gt $1 ]]; then
    divider=$1
  fi
else
  echo "Usage: getTokens.sh <current_num_token> <divider_num>"
  exit
fi

nodetool info -T | tail -n $num_tokens | awk -F": " '{print $2}' > /tmp/tokenlist.txt

#tokenlist=$(sed -n 1~"$divider"p /tmp/tokenlist.txt | tr ' ' ',')
#echo $tokenlist

sed -n 1~"$divider"p /tmp/tokenlist.txt | awk '{printf("%s, ", $0)}' | sed 's/, $//g'

echo
