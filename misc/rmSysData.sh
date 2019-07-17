#! /bin/bash

DSE_DATA_HOME=/var/lib/cassandra
DATA_DIR=data
SAVED_CACHES_DIR=saved_caches

filelist=$(ls $DSE_DATA_HOME/$DATA_DIR/ | grep -Ev 'dse_security|system_auth|testks')

if [[ $1 == "yes" ]]; then
   echo "Deleting saved_cahces..."
   sudo rm -rf $DSE_DATA_HOME/$SAVED_CACHES_DIR/*

   echo "Deleting system keyspaces other than dse_security and system_auth..."
   echo "  >>>" $filelist

   for file in $filelist
   do
      sudo rm -rf $DSE_DATA_HOME/$DATA_DIR/$file
   done
else
   echo "Exit with on action!"
   exit
fi
