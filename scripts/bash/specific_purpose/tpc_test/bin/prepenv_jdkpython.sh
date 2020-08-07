#! /bin/bash

sudo apt install -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common
wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
sudo apt update
sudo apt install -y adoptopenjdk-8-hotspot
sudo apt install -y python2
sudo apt install -y python-pip
sudo apt install -y libaio1
sudo apt install -y fuse
sudo apt install -y sysstat

