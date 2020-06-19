# Overview

In this tutorial, I'm going to demonstrate how to "semi-dynamically" provision local PersistentVolumes (PVs) in a K8s cluster. 

---

K8s PV is a cluster-level resource that represents a piece of storage. A PV has its own life cycle that is independent of the life cycle of a Pod that is provisioned in the cluster. Therefore, the data stored in a PV won't be lost even when there is Pod failure (aka, persistent). A Pod requests the PV storage using a PersistentVolumeClaim(PVC).

There are 2 ways to provision a PV:
* A cluster administrator can manually create one. This is called as **static** provision.
* A PV can also be **dynamically** provisioned through a PVC with a pre-defined [storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/).

PV types are implemented through plug-ins ([list](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#types-of-persistent-volumes)). Many of the PV types are "remote" by nature and can be dynamically provisioned. 

But there do have cases where storage is preferred, such as for better performance. Traditionally, K8s offers the local storage option of [HostPath Volume](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath). This option, though, has quite some limitations, the biggest of which is it can't participate in K8s's resource-aware scheduling and there is no node affinity associated with it. 

Since K8s 1.14, K8s has introduced the concept of ***Local PV*** ([GA announcement](https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/)) in order to oversome the limitations of *HostPath* volume. 

Please note that a *Local PV* is by nature still static. However, there are some **external static provisioners** that can help make the *Local PV* creation and management process semi-dynamic. In this tutorial, I'm using one popular external static provisioner from [K8s SIGs](https://github.com/kubernetes-sigs) called [sig-storage-local-static-provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner). 

Another common external static provisioner is from [Rancher company](https://rancher.com/)'s [local-path-provisioner](https://github.com/rancher/local-path-provisioner) and it is not the focus of this tutorial.