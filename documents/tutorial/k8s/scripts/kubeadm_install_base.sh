#! /bin/bash

######################
# Prerequisite check and settings
#
# Check MAC address 
NET_INTERFACE="eth0"
MAC_ADDR=`ip link show $NET_INTERFACE | awk '/ether/ {print $2}'`
echo "mac address ($NET_INTERFACE): $MAC_ADDR"

# Check product_uuid
PRODUCT_UUID=`sudo cat /sys/class/dmi/id/product_uuid`
echo "product_uuid: $MAC_ADDR"

# Enable check "br_netfilter" module
MOD_ENABLED=`sudo modprobe br_netfilter`
if [[ -z "$MOD_ENABLED" ]]; then
   sudo modprobe br_netfilter
fi

# Make sure the node's iptable can see bridged traffic
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system


######################
# Install Docker container runtime
#
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker `whoami`

# Make sure "systemd" is used as the cgroup driver for Docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docke


######################
# Install "kubeadm", "kubelet", and "kubectl"
#
sudo apt-get update
sudo apt-get install -y apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
export K8S_VER="1.17.6-00"
sudo apt-get install -y kubelet=$K8S_VER kubeadm=$K8S_VER kubectl=$K8S_VER

sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet