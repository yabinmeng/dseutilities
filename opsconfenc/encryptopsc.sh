#!/bin/bash

usage() {
   echo "Usage: encryptopsc.sh <text_to_be_encrypted>"
}

if [[ $# != 1 ]]; then
   usage
   exit
fi

./opscencwrapper.exp $1 | tail -n1 | head -n1
