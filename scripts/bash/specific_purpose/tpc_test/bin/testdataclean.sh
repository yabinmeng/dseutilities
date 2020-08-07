#! /bin/bash

usageExit() {
   echo "testdataclean.sh [default|pd-std|pd-ssd|local-ssd]"
   exit
}

if [[ $# != 1 ]]; then
   usageExit
fi

DSE_DATA_HOMEDIR=""
if [[ "$1" == "default" ]]; then
   DSE_DATA_HOMEDIR="/var/lib/cassandra"
elif [[ "$1" == "pd-std" ]]; then
   DSE_DATA_HOMEDIR="/data_pd_std/cassandra"
elif [[ "$1" == "pd-ssd" ]]; then
   DSE_DATA_HOMEDIR="/data_pd_ssd/cassandra"
elif [[ "$1" == "local-ssd" ]]; then
   DSE_DATA_HOMEDIR="/data_local_ssd/cassandra"
else
    usageExit
fi

echo $DSE_DATA_HOMEDIR

cqlsh 10.128.0.9 -e "drop keyspace baselines"
sudo rm -rf $DSE_DATA_HOMEDIR/commitlog/* $DSE_DATA_HOMEDIR/saved_caches/* $DSE_DATA_HOMEDIR/data/baselines
