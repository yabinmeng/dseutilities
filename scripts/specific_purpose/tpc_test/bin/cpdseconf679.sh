#! /bin/bash

DSECONF_BKUP_DIR=~/conf_bkup/dse
BACKUP_DSE_VER=6.7.9

usageExit() {
   echo "cpdseconf.sh [002|003] [default|pd-std|pd-ssd|local-ssd] [aio|noaio]"
   exit
}

if [[ $# != 2 && $# != 3 ]]; then
   usageExit
fi

NODE_NAME=""
if [[ "$1" == "002" ]]; then
   NODE_NAME="node002"
elif [[ "$1" == "003" ]]; then
   NODE_NAME="node003"
else
    usageExit
fi

SUBDIR=""
if [[ "$2" == "default" ]]; then
   SUBDIR="default"
elif [[ "$2" == "pd-std" ]]; then
   SUBDIR="pd-std"
elif [[ "$2" == "pd-ssd" ]]; then
   SUBDIR="pd-std"
elif [[ "$2" == "local-ssd" ]]; then
   SUBDIR="local_ssd"
else
   usageExit
fi

if [[ "$2" != "default" ]]; then
   if [[ "$3" == "noaio" ]]; then
      SUBDIR="$SUBDIR""/noaio"
   elif [[ "$3" == "aio" ]]; then
      SUBDIR="$SUBDIR""/aio"
   else
      usageExit
   fi
fi

CURRUN_DSE_VER=$(dse -v)
if [[ "$BACKUP_DSE_VER" != "$CURRUN_DSE_VER" ]]; then
   echo "Copying wrong version of DSE configuraiton files (currently running DSE version: $CURRUN_DSE_VER; backup DSE version: $BACKUP_DSE_VER)"
   exit
fi

sudo cp $DSECONF_BKUP_DIR/$NODE_NAME/$BACKUP_DSE_VER/jvm.options $DSE_HOME/resources/cassandra/conf

echo "$DSECONF_BKUP_DIR/$NODE_NAME/$SUBDIR"
sudo cp $DSECONF_BKUP_DIR/$NODE_NAME/$BACKUP_DSE_VER/$SUBDIR/cassandra.yaml $DSE_HOME/resources/cassandra/conf
sudo cp $DSECONF_BKUP_DIR/$NODE_NAME/$BACKUP_DSE_VER/$SUBDIR/cassandra-env.sh $DSE_HOME/resources/cassandra/conf
