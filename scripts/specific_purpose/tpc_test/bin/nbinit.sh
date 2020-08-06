#! /bin/bash

NB_HOMEDIR=/home/yabinmeng

$NB_HOMEDIR/nb run driver=cql workload=$NB_HOMEDIR/cql-iot.yaml host="10.128.0.9" tags=phase:schema threads=1 --progress console:10s --show-stacktraces
#$NB_HOMEDIR/nb run driver=cql workload=$NB_HOMEDIR/cql-iot.yaml host="10.128.0.9" tags=phase:rampup threads=10 cycles=1M --progress console:10s
