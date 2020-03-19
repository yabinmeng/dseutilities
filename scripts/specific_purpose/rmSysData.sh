#! /bin/bash


#
# NOTE: this script was designed to quickly remove C* data from local node. Please specify 
#       the appliation keyspace names and system keyspace names (divided by |) that want to
#       be excluded from the deletion
#


DSE_DATA_HOME=/var/lib/cassandra
DATA_DIR=data
SAVED_CACHES_DIR=saved_caches

# If multiple keyspaces are specified, use "|" as the separator with no space around.
SYSKS_EXCLUDE_LIST="dse_security|system_auth"
APPKS_LIST="testks|testks2"

echo "$SYSKS_EXCLUDE_LIST|$APPKS_LIST"

filelist=$(ls $DSE_DATA_HOME/$DATA_DIR/ | grep -Ev "$SYSKS_EXCLUDE_LIST|$APPKS_LIST")

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
   echo "Exit with no action!"
   exit
fi
