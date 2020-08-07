#! /bin/bash

if [[ ! -d $CASSANDRA_LOG_DIR ]]; then
   sudo mkdir -p $CASSANDRA_LOG_DIR
   sudo chown -R cassandra:cassandra $CASSANDRA_LOG_DIR
fi

DATA_VAR_LIB_CASS=/var/lib/cassandra
DATA_PD_STD=/data_pd_std
DATA_PD_SSD=/data_pd_ssd
DATA_LOCAL_SSD=/data_local_ssd

if [[ ! -d /var/lib/cassandra ]]; then
   sudo mkdir -p $DATA_VAR_LIB_CASS
   sudo chown -R cassandra:cassandra $DATA_VAR_LIB_CASS
fi

if [[ ! -d $DATA_PD_STD ]]; then
   sudo mkdir -p $DATA_PD_STD
fi

if [[ ! -d $DATA_PD_SSD ]]; then
   sudo mkdir -p $DATA_PD_SSD
fi

if [[ ! -d $DATA_LOCAL_SSD ]]; then
   sudo mkdir -p $DATA_LOCAL_SSD
fi

echo
echo "=== rotational(sdb): $(cat /sys/block/sdb/queue/rotational) ==="
sudo mkfs.ext4 -F /dev/sdb
sudo mount /dev/sdb $DATA_PD_STD

echo
echo "=== rotational(sdc): $(cat /sys/block/sdc/queue/rotational) ==="
sudo mkfs.ext4 -F /dev/sdc
sudo mount /dev/sdc $DATA_PD_SSD

echo
echo "=== rotational(nvme0n1): $(cat/sys/block/nvme0n1/queue/rotational)   "
sudo mkfs.ext4 -F /dev/nvme0n1
sudo mount /dev/nvme0n1 $DATA_LOCAL_SSD

sudo chown -R cassandra:cassandra $DATA_PD_STD
sudo chown -R cassandra:cassandra $DATA_PD_SSD
sudo chown -R cassandra:cassandra $DATA_LOCAL_SSD
