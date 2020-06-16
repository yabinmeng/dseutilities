# Overview

"kubeadm" is [Kubernetes'](https://kubernetes.io/) packaged utility to install and configure a minumum viable k8s cluster (aka, vanilla k8s cluster) that follows "kubeadm init and kubeadm join" as fast path best practices.

Please note that "kubeadm" utility only does cluster bootstrapping, but not provisisoning. Therefore, this installation method requires the underlying machines to be prepared in advance. It also doesn't include other nice-to-have "add-ons"/features such as k8s dashboard.

In this tutorial, a step-by-step procedure is presented regarding how to use kubeadm to install and configure a vanilla k8s cluster with a single control-plane node. For the demonstration purpose, 3 VM instances are provisioned in advance with the following specs and configurations on each instance
* Ubuntu Xenial (16.04.6 LTS) OS is installed. 
* 4 vCPU and 16GB total system

#  Prerequisites

There are a few prerequisite checks/operations that need to be done on each of the hosting machine before we start provisioning a k8s cluster.

* Disable SWAP

* Verify MAC address and product_uuid are unique on each node. 

  * Use the following command to check each node's MAC address (replacing "eth0" with your network interface name)

```bash
ifconfig eth0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'
```
```bash
ip link show eth0 | awk '/ether/ {print $2}'
```

  * Verify product_uuid 


# Install "kubeadm"