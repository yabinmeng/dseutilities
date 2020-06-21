# Overview

In this tutorial, I'm going to demonstrate how to ***semi-dynamically*** provision local PersistentVolumes (PVs) in a  K8s cluster. 

---

K8s PV is a cluster-level resource that represents a piece of storage. A PV has its own life cycle that is independent of the life cycle of a Pod that is provisioned in the cluster. Therefore, the data stored in a PV won't be lost even when there is Pod failure (aka, persistent). A Pod requests the PV storage using a PersistentVolumeClaim(PVC).

There are 2 ways to provision a PV:
* A cluster administrator manually creates one. This is called **static** provision.
* A PV can also be **dynamically** provisioned through a pre-defined [storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/) by a PVC.

PV types are implemented through plug-ins ([list](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#types-of-persistent-volumes)). Many of the PV types are "remote" by nature and can be dynamically provisioned. 

But there do have cases when local storage is preferred, such as for better performance. Traditionally, K8s offers the local storage option via [HostPath Volume](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath). This option, however, has quite some limitations, the biggest of which is it can't participate in K8s's resource-aware scheduling and there is no node affinity associated with it. Since K8s 1.14, K8s has introduced the concept of ***Local PV*** ([GA announcement](https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/)) in order to address the challenges that are faced with *HostPath* volume. 

Please note that a *Local PV* is by nature still static; but there are some **external static provisioners** that can help make the *Local PV* creation and management process semi-dynamic. In this tutorial, I'm demonstrating how to do so through one popular external static provisioner from [K8s SIGs](https://github.com/kubernetes-sigs) called [sig-storage-local-static-provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner). 

Another common external static provisioner is from [Rancher company](https://rancher.com/)'s [local-path-provisioner](https://github.com/rancher/local-path-provisioner) and it is not the focus of this tutorial.

## K8s Cluster Overview

The tutorial has been run against a K8s cluster that was created using **kubeadm** utility (see [procedure](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/kubeadm_install.md)). This cluster has 3 VM instances and for testing purpose, ***the control-plane/master node is configured to allow launching Pods on it***. 

```bash
$ kubectl get nodes
NAME                                     STATUS   ROLES    AGE   VERSION
ip-10-101-32-187.srv101.dsinternal.org   Ready    <none>   42h   v1.17.6
ip-10-101-35-135.srv101.dsinternal.org   Ready    <none>   42h   v1.17.6
ip-10-101-36-132.srv101.dsinternal.org   Ready    master   47h   v1.17.6
```

# K8s SIG Local Storage Static Provisioner

[sig-storage-local-static-provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) is part of K8s community efforts under the special interest group (SIG) umbrella. The main goal of this effort is to simplify the local storage management in a K8s cluster so that the local storage can be utilized through a *Local PV* which contains *node affinity* information that can be used to schedule Pods to the nodes with the right storage space assignment. In the discussion below, I'll use the terms of "the provisioner utility", "the provisioner", or simply "the utility" to refer to SIG Local Storage Static Provisioner.

The utility is able to detect local storage spaces and automatically create PVs out of it on each K8s node as long as the local storage spaces is created following certain conditions:

* In the provisioner configuration, specify a discovery directory
* The local storage space is prepared in a way that links to the discovery directory:
  * **Filesystem volumeMode PV**: this is the default mode and requires the local storage space to be mounted under the discovery directory.
  * **Block volumeMode PV**: this requires creating a symbolic link under discovery directory that points to the block device.

## Procedures

Depending on the underlying infrastructure on which the K8s cluster is running (eg. bare-metal or cloud vendor infrastructures like GCE, GKE, EKS, or AKS), the actual procedure of using this utility to create and manage PVs is a little bit different. 

In this tutorial, I'm demonstrating the procedure of how to manage and create local PVs on a bare-metal infrastructure that follows the default "Filesystem volumeMode". The procedure of running on cloud vendor infrastructures is in general a bit simpler with cloud infrastructure specific differences. Please follow the utility's documentation for more details.

--- 

### Specify and Create The Provisioner Discovery Directory

On each node in the cluster, create a same folder (e.g. /mnt/disks) as the provisioner discovery directory:

```bash
$ sudo mkdir -p /mnt/disks
```

### Prepare Local Storage Spaces

**NOTE** This needs to be executed on each node in the cluster!

Since it is impossible to buy and attach a new hard drive to each node in the cluster in this tutorial, I am simulating a block device using a [loop device](https://en.wikipedia.org/wiki/Loop_device) (which is to simulates a block device based on a file). 

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

### Generate Provisioner K8s Resource File (.yaml) Using Helm

**NOTE** This only needs to be executed on control-plane/master node in the cluster!

The provisioner defines a bundle of K8s resources of the following types:
* ServiceAccount
* ConfigMap
* StorageClass
* ClusterRole
* ClusterRoleBinding (for PV and Node)
* DaemonSet

The easiest way to generate a customized resource definition file for the above types of resources that is relevant to your own case is through the [Helm](https://helm.sh/) chart template that is provided.

#### (Optional) Install Helm 

The procedure of installing Helm on Ubuntu is as below:

```bash
$ curl https://helm.baltorepo.com/organization/signing.asc | sudo apt-key add -

$ sudo apt-get install apt-transport-https --yes

$ echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

$ sudo apt-get update

$ sudo apt-get install helm

# Check Helm version
$ helm version
version.BuildInfo{Version:"v3.2.4", GitCommit:"0ad800ef43d3b826f31a5ad8dfbb4fe05d143688", GitTreeState:"clean", GoVersion:"go1.13.12"}
```

#### Customize the Resource Definition File from Helm Template File

* Download the utility's source code

```bash
$ git clone --depth=1 https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner.git
```

* Run the following command to generate a customized provisioner resource file 

```bash
# The general form of the command
# $ helm template -f <template_value_yaml_file> <release_name> [--namespace <namespace_name>]./sig-storage-local-static-provisioner/helm/provisioner > <provisioner_resource_yaml_file>

# The command used in this tutorial
$ helm template -f ./values.yaml local-storage ./sig-storage-local-static-provisioner/helm/provisioner > local-storage-provisioner.yaml
```

In the above example, the customization of the generated resource definition file (from the proved template file) is controlled by "<template_value_yaml_file>". The utility has provided an example ([values.yaml](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/blob/master/helm/provisioner/values.yaml)).

The customization file ("values.yaml") used in this tutorial can be found [here(https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/local_pv_sig/helm/values.yaml)]. In particular, the customization that has been made in this tutorial is related with ***StorageClass*** resource.

```yaml
#
# Configure storage classes.
#
classes:
- name: local-storage # Defines name of storage classe.
  # Path on the host where local volumes of this storage class are mounted
  # under.
  hostDir: /mnt/disks
  # Optionally specify mount path of local volumes. By default, we use same
  # path as hostDir in container.
  # mountDir: /mnt/fast-disks
  # The volume mode of created PersistentVolume object. Default to Filesystem
  # if not specified.
  volumeMode: Filesystem
  # Filesystem type to mount.
  # It applies only when the source path is a block device,
  # and desire volume mode is Filesystem.
  # Must be a filesystem type supported by the host operating system.
  fsType: ext4
  # File name pattern to discover. By default, discover all file names.
  namePattern: "'*'"
  blockCleanerCommand:
  #  Do a quick reset of the block device during its cleanup.
  #  - "/scripts/quick_reset.sh"
  #  or use dd to zero out block dev in two iterations by uncommenting these lines
  #  - "/scripts/dd_zero.sh"
  #  - "2"
  # or run shred utility for 2 iteration.s
     - "/scripts/shred.sh"
     - "2"
  # or blkdiscard utility by uncommenting the line below.
  #  - "/scripts/blkdiscard.sh"
  # Uncomment to create storage class object with default configuration.
  storageClass: true
  # Uncomment to create storage class object and configure it.
  storageClass:
    reclaimPolicy: Delete # Available reclaim policies: Delete/Retain, defaults: Delete.
    isDefaultClass: false # set as default class
```

The generated customized resource definition file for the local storage provisioner for this tutorial can be found [**here**](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/local_pv_sig/helm/generated/local-storage-provisioner.yaml).

#### Install The Provisioner Resources

Now the provisioner resource definition file is generated, we can install it in the K8s cluster using the following command and create the corresponding resources in the cluster. The command output shows the created resource types and names.

```bash
$ kubectl create -f ./local-storage-provisioner.yaml
serviceaccount/local-static-provisioner created
configmap/local-static-provisioner-config created
storageclass.storage.k8s.io/local-storage created
clusterrole.rbac.authorization.k8s.io/local-static-provisioner-node-clusterrole created
clusterrolebinding.rbac.authorization.k8s.io/local-static-provisioner-pv-binding created
clusterrolebinding.rbac.authorization.k8s.io/local-static-provisioner-node-binding created
daemonset.apps/local-static-provisioner created
```

Once the above provisioner resources are created in the K8s cluster, the provisioner will scan the specified discovery folder and if there is any local storage spaces mounted under the folder, it will create *Local PVs* **automatically**. The number of the *Local PVs* on each node is equal to the number of mounted local storage spaces under the discovery folder.

In this tutorial, on each node there is only 1 local storage space that is mounted under the provisioner discovery folder. Since there are 3 nodes in the cluster, we're expecting to see 3 *Local PVs* in the cluster, which is confirmed from the following output.  **NOTE** that if the control-plane node is NOT enabled to launch Pods (which is true by default) on it, we would ONLY see 2 *Local PVs* in the cluster, one per worker node.

```bash
$ kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
local-pv-514b438b   968Mi      RWO            Delete           Available           local-storage            4h23m
local-pv-5aa1117a   968Mi      RWO            Delete           Available           local-storage            4h23m
local-pv-9dd3fb96   968Mi      RWO            Delete           Available           local-storage            4h23m
```

Let's check the details of one Local PV and we can see some important attributes such as "Node Affinity", "Source Type", "Source Path", and etc. **NOTE** that double-checking the "Node Affinity" attribute confirms that each each *Local PV* only confirms to one particular node and can NOT be allocated to multiple nodes.

```bash
$ kubectl describe pv local-pv-514b438b
Name:              local-pv-514b438b
Labels:            <none>
Annotations:       pv.kubernetes.io/provisioned-by: local-volume-provisioner-ip-10-101-35-135.srv101.dsinternal.org-3c2d77b2-17c6-4575-bbb6-7cc3e40fd1a0
Finalizers:        [kubernetes.io/pv-protection]
StorageClass:      local-storage
Status:            Available
Claim:
Reclaim Policy:    Delete
Access Modes:      RWO
VolumeMode:        Filesystem
Capacity:          968Mi
Node Affinity:
  Required Terms:
    Term 0:        kubernetes.io/hostname in [ip-10-101-35-135.srv101.dsinternal.org]
Message:
Source:
    Type:  LocalVolume (a persistent volume backed by local storage on a node)
    Path:  /mnt/disks/2ba4f792-5ad9-4560-a010-f1521f5dc03f
Events:    <none>
```

At this point, since *Local PVs* are created, the K8s cluster can allocate it to the Pods through *PVC* requests; and all Pods that belong to a particular node can **ONLY** utilize the local storage spaces that are dedicated to that node. 

# Summary

Please **NOTE** that a *Local PV* can be created in a purely static and manual approach by defining a PV resource definition file - an example from K8s [document](https://kubernetes.io/docs/concepts/storage/volumes/#local) is copied below.

```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-pv
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - example-node
```

But creating and managing *Local PV* resource definition files as above can be cumbersome and error-prone, especially when we consider that there might be multiple *Local PVs* to be managed per node and meanwhile the proper *Node Affinity* attributes have to be maintained properly.

Int his tutorial, we explored a ***semi-dynamic*** way of provisioning *Local PVs* in a K8s cluster through a local storage provisioner. By using the provisioner, we still need to statically and manually (can be scripted) provision the actual local storage spaces per node; but the provisioner can do the rest of the work of discovering, creating, and configuring *Local PVs* automatically.