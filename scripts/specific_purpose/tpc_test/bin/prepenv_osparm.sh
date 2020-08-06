#! /bin/bash

for DVC in 'sdb' 'sdc' 'nvme0n1'
do
   echo 8 > /sys/block/$DVC/queue/read_ahead_kb
   echo 128 > /sys/block/$DVC/queue/nr_requests
done


