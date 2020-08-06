#! /bin/bash

echo "DXAGT_HOME=$DXAGT_HOME"
sudo -u cassandra $DXAGT_HOME/bin/datastax-agent &
