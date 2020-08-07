#! /bin/bash

pid=$(ps -ef | grep opscenter | grep -v grep | awk '{print $2}')
if [[ "$pid" != "" ]]; then
   echo $pid
   sudo kill -9 $pid
fi
