#! /bin/bash

NB_HOMEDIR=/home/yabinmeng

$NB_HOMEDIR/nb run driver=cql workload=$NB_HOMEDIR/cql-iot.yaml pooling=5:10 host="10.128.0.9" tags=phase:main read_ratio=1 read_cl=LOCAL_ONE write_ratio=9 write_cl=LOCAL_ONE stride=50 threads=50 --progress console:10s cycles=50M
