# Overview

"kubeadm" is [Kubernetes'](https://kubernetes.io/) packaged utility to install and configure a minumum viable k8s cluster (aka, vanilla k8s cluster) that follows "kubeadm init and kubeadm join" as fast path best practices.

Please note that "kubeadm" utility only does cluster bootstrapping, but not provisisoning. Therefore, this installation method requires the underlying machines to be prepared in advance. It also doesn't include other nice-to-have "add-ons"/features such as k8s dashboard.

In this tutorial, a step-by-step procedure is presented regarding how to use kubeadm to install and configure a vanilla k8s cluster with a single control-plane node. For the demonstration purpose, 3 VM instances are provisioned in advance with the following specs and configurations on each instance
*Ubuntu Xenial (16.04.6 LTS) OS is installed
*4 vCPU and 16GB total system

# Prerequisites

There are a few prerequisite checks/operations that need to be done on each of the hosting machine before we start provisioning a k8s cluster.

* Disable SWAP

* Verify ***MAC address*** is unique each instance (NOTE: replace "eth0" with the right network adaptor name)

```bash
ifconfig eth0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}', or
ip link show eth0 | awk '/ether/ {print $2}'
```

* Verify ***product_uuid*** is unique on each instance

```bash
sudo cat /sys/class/dmi/id/product_uuid
```

* Check if Linux module ***br_netfilter*** is enabled. Enable it if not. This is required for the next step.

```bash
// check if "br_netfilter" module is enabled (enabled if value is returned)
lsmod | grep br_netfilter

// Enable "br_netfilter" module
sudo modprobe br_netfilter
```

* Make sure each instance's iptables can see bridged traffic

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```

* Make sure the following ports are open on the control-plan instance/node and the worker instances/nodes

**Control-plane Instance/Node**

| Description        | Protocol/Port       | Note              |
| ------------------ | ------------------- | ------------------|
| Kubernetes API server | TCP/6443 ||
| etcd server client API | TCP/2379-2380 | Used by kube-apiserver, etcd |
| Kubelet API | TCP/10250 | Kubelet on the control-plane node |
| kube-scheduler | TCP/10251 ||
| kube-controller-manager | TCP/10252 ||



# Install "kubeadm"