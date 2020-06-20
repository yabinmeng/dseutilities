# Overview

In this tutorial, I'm going to demonstrate how to "semi-dynamically" provision local PersistentVolumes (PVs) in a  K8s cluster. 

---

K8s PV is a cluster-level resource that represents a piece of storage. A PV has its own life cycle that is independent of the life cycle of a Pod that is provisioned in the cluster. Therefore, the data stored in a PV won't be lost even when there is Pod failure (aka, persistent). A Pod requests the PV storage using a PersistentVolumeClaim(PVC).

There are 2 ways to provision a PV:
* A cluster administrator manually creates one. This is called **static** provision.
* A PV can also be **dynamically** provisioned through a pre-defined [storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/) by a PVC.

PV types are implemented through plug-ins ([list](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#types-of-persistent-volumes)). Many of the PV types are "remote" by nature and can be dynamically provisioned. 

But there do have cases when local storage is preferred, such as for better performance. Traditionally, K8s offers the local storage option via [HostPath Volume](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath). This option, however, has quite some limitations, the biggest of which is it can't participate in K8s's resource-aware scheduling and there is no node affinity associated with it. Since K8s 1.14, K8s has introduced the concept of ***Local PV*** ([GA announcement](https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/)) in order to adress the challenges that are faced with *HostPath* volume. 

Please note that a *Local PV* is by nature still static; but there are some **external static provisioners** that can help make the *Local PV* creation and management process semi-dynamic. In this tutorial, I'm demonstrating how to do so through one popular external static provisioner from [K8s SIGs](https://github.com/kubernetes-sigs) called [sig-storage-local-static-provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner). 

Another common external static provisioner is from [Rancher company](https://rancher.com/)'s [local-path-provisioner](https://github.com/rancher/local-path-provisioner) and it is not the focus of this tutorial.

## K8s Cluster Overview

The tutorial has been run against a K8s cluster that was created using **kubeadm** utility (see [procedure](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/kubeadm_install.md)). This cluster has 3 VM instances and for testing purpose, the control-plane/master node is configured to allow launching Pods on it. 

```bash
$ kubectl get nodes
NAME                                     STATUS   ROLES    AGE   VERSION
ip-10-101-32-187.srv101.dsinternal.org   Ready    <none>   42h   v1.17.6
ip-10-101-35-135.srv101.dsinternal.org   Ready    <none>   42h   v1.17.6
ip-10-101-36-132.srv101.dsinternal.org   Ready    master   47h   v1.17.6
```

# K8s SIG Local Storage Static Provisioner

[sig-storage-local-static-provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) is part of K8s community efforts under the special intererst group (SIG) umbrella. The main goal of this effort is to simplify the local storagement management in a K8s cluster so that the local storage can be utilized through a *Local PV* which contains *node affinity* information that can be used to schedule Pods to the correct nodes while maintining the right storage space assignment. In the discussion below, I'll use the terms of "the provisioner utility", "the provisioner", or simply "the utility" exchangeably to refer to SIG Local Storage Static Provisioner.

The utility is able to detect local storage spaces and automatically create PVs out of it on each K8s node as long as the local storage spaces is created following certain conditions:

* In the provisioner configuration, specify a discovery directory
* The local storage space is prepared in a way that links to the discovery directoy
** **Filesystem volumeMode PV**: this is the default mode and requires the local storage space to be mounted under the discovery directory.
** **Block volumeMode PV**: this requires creating a symbolic link under discovery directory that points to the block device.

## Procedures

Depending on the underlying infrastructure on which the K8s clsuter is running (eg. baremetal or cloud vendor infrastructures like GCE, GKE, EKS, or AKS), the actual procedure of using this utility to create and manage PVs is a little bit different. 

In this tutorial, I'm demonstrating the procedure of how to manage and create local PVs on a baremetal infrastructure that follows the default "Filesystem volumeMode". The procedure of running on cloud vendor infrastructures is in general a bit simpler with cloud infrastructure specific differences. Please follow the utility's documentation for more details.

--- 

### Specifiy and Create The Provisioner Discovery Directory

On each node in the cluster, create a same folder (e.g. /mnt/disks) as the provisioner discovery directory:

```bash
$ sudo mkdir -p /mnt/disks
```

### Prepare Local Storage Spaces

Since it is impossible to buy and attach a new hard drive to each node in the cluster, I'm using a Linux [loop device](https://en.wikipedia.org/wiki/Loop_device) to simulate a block device based out of a file.

* Create a 1 GB file (size can be changed) as the underlying file for the loop device

```bash
$ sudo dd if=/dev/zero of=/root/myloopbackfile.img bs=100M count=10
10+0 records in
10+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 1.18164 s, 887 MB/s
```

* Create a loop device out of the previously created file.

```bash
# Create the loop device
$ sudo losetup -fP /root/myloopbackfile.img

# Verify the created device
$ sudo losetup -a
/dev/loop0: [64770]:783 (/root/myloopbackfile.img)
```

* Create *ext4* file system on the created device

```bash
$ sudo mkfs.ext4 /dev/loop0
```

* Mount the device under the provisioner discovery directory. Please note mounting the device using its UUID (instead of the name) is considered as a best-practice and highly recommended.

```bash
$ DISK_UUID=$(sudo blkid -s UUID -o value /dev/loop0)
$ sudo mkdir /mnt/disks/$DISK_UUID
$ sudo mount -t ext4 /dev/loop0 /mnt/disks/$DISK_UUID
```

Verify the device is successfully mounted:

```bash
$ echo $DISK_UUID
63bccce1-06fd-434b-8ec9-35caed74168c

$ df -hT /dev/loop0
Filesystem     Type  Size  Used Avail Use% Mounted on
/dev/loop0     ext4  969M  1.3M  902M   1% /mnt/disks/63bccce1-06fd-434b-8ec9-35caed74168c
```