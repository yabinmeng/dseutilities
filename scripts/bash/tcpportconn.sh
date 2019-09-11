#!/bin/bash

usage () {
   echo "$0 <HOST_ADDRESS> <PORT_NUMBER>"
}

if [[ $# != 2 ]]; then
   usage
   exit
fi

SERVER=$1
PORT=$2
</dev/tcp/$SERVER/$PORT
if [ "$?" -ne 0 ]; then
   echo "Connection to $SERVER on port $PORT failed"
   exit 1
else
   echo "Connection to $SERVER on port $PORT succeeded"
   exit 0
fi
