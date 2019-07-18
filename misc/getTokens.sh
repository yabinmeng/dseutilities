#!/bin/bash

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
