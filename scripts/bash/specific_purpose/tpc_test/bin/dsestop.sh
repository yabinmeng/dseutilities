#! /bin/bash

echo "DSE_HOME=$DSE_HOME"
sudo -u cassandra $DSE_HOME/bin/dse cassandra-stop &
