#! /bin/bash


usage() {
   echo
   echo "ddack_backup.sh [-h | <keyspace list>]"
   echo
}

if [[ $1 == "-h" ]]; then
   usage
   exit 0
fi

# DDAC installation home directory
DDAC_HOME=/opt/ddac5116

# Get the current date and time (in hour)
CURTIME_IN_HOUR=`date '+%F_%H'`
#echo $CURTIME_IN_HOUR

# Temporary file name to hold "nodetool snapshot" command output
TMPFILE=tmpoutputfile

# use the current date and time (in hour) as the snapshot tag name
if [[ "$#" -eq 0 ]]; then
   echo ">> Take a C* snapshot named \"$CURTIME_IN_HOUR\" for all keyspaces"
   $DDAC_HOME/bin/nodetool snapshot -t $CURTIME_IN_HOUR &> $TMPFILE
else
   echo ">> Take a C* snapshot named \"$CURTIME_IN_HOUR\" for specified keyspaces: $*"
   $DDAC_HOME/bin/nodetool snapshot -t $CURTIME_IN_HOUR -- $* &> $TMPFILE
fi

# Check if "nodetool snapshot" command has executed successfully
ERRMSG=`grep error $TMPFILE`

if [[ $ERRMSG != "" ]]; then
   echo "   [Failed] $ERRMSG"
else
   echo "   [Succeeded] Snapshot $CURTIME_IN_HOUR has been taken successfully."
fi

# Delete the temporary output file
rm -rf $TMPFILE
