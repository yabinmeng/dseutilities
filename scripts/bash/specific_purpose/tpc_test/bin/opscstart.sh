#! /bin/bash

echo "OPSC_HOME=$OPSC_HOME"
sudo -u cassandra $OPSC_HOME/bin/opscenter &
