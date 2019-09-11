#!/bin/bash

usage() {
   echo "Usage: encryptdse.sh <text_to_be_encrypted>"
}

if [[ $# != 1 ]]; then
   usage
   exit
fi

./dseencwrapper.exp $1 | tail -n2 | head -n1
