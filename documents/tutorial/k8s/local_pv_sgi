# Overview

In this tutorial, I'm going to demonstrate how to "dynamically" provision local PersistentVolumes (PVs) in a K8s cluster. 

## Very Brief Review of K8s PV and PVC

K8s PV is a cluster-level resource that represents a piece of storage. A PV has its own life cycle that is independent of the life cycle of a Pod that is provisioned in the cluster. Therefore, the data stored in a PV won't be lost even when there is Pod failure (aka, persistent). A Pod requests the PV storage using a PersistentVolumeClaim(PVC).

There are 2 ways to provision a PV:
* A cluster administrator can manually create one. This is called as **static** provision.
* A PV can also be **dynamically** provisioned through a PVC with a pre-defined [storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/).

PV types are implemented through plug-ins ([list](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#types-of-persistent-volumes)). Many of the PV types are "remote" by nature and can be dynamically provisioned.  

However, in cases when local storage is preferred (e.g. for better performance), the traditional K8s [HostPath Volume](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath) is purely static and not subject to resource-aware scheduling. 

Since K8s 1.14, K8s has introduced the concept of ***Local PV*** ([GA announcement](https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/)


