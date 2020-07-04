# Overiew

Earlier this year on Mar. 31, DataStax has announced the [release](https://www.datastax.com/press-release/datastax-helps-apache-cassandra-become-industry-standard-scale-out-cloud-native-data) of K8s operator for Apache C*. Later this year on April 7th, DataStax also GA-released DataStax Enterprise (DSE) version 6.8 and K8s operator is part of this release. For simplicity purpose, I'm going to use the term "C* Operator" to refer to K8s operator for Apache C* and DSE.   

In this tutorial, I will demonstrate how to provision a DSE cluster (through C* Operator) on the K8s cluster that we created earlier ([K8s cluster](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/kubeadm_install.md).

Note that K8s cluster has 3 nodes and the master node is configured to allow launching Pods on it.

```bash
$ kubectl get nodes
NAME                                     STATUS   ROLES    AGE     VERSION
ip-10-101-32-187.srv101.dsinternal.org   Ready    <none>   4h15m   v1.17.6
ip-10-101-32-217.srv101.dsinternal.org   Ready    <none>   4h15m   v1.17.6
ip-10-101-35-135.srv101.dsinternal.org   Ready    master   4h19m   v1.17.6
```

# Install C* Operator

At the core of C* Operator, it is an API extension of K8s through [Customer Resource Definition (CRD)](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/). Currently it supports K8s versions from 1.13 to 1.18 (1.15 and above is recommended). The corresponding CRDs can be found from [here] (https://github.com/datastax/cass-operator).

The procedure of installing C* Operator (version 1.17) is as below (executed from K8s master node):

```bash
$ wget https://raw.githubusercontent.com/datastax/cass-operator/master/docs/user/cass-operator-manifests-v1.17.yaml

$ kubectl apply -f cass-operator-manifests-v1.17.yaml
namespace/cass-operator created
serviceaccount/cass-operator created
secret/cass-operator-webhook-config created
customresourcedefinition.apiextensions.k8s.io/cassandradatacenters.cassandra.datastax.com created
clusterrole.rbac.authorization.k8s.io/cass-operator-cluster-role created
clusterrolebinding.rbac.authorization.k8s.io/cass-operator created
role.rbac.authorization.k8s.io/cass-operator created
rolebinding.rbac.authorization.k8s.io/cass-operator created
service/cassandradatacenter-webhook-service created
deployment.apps/cass-operator created
validatingwebhookconfiguration.admissionregistration.k8s.io/cassandradatacenter-webhook-registration created
```

Pay attention to the command line output and we can see that the following K8s resources are created:

| Resource Type | Resource Name |
| ----------- | ----------- |
| namespace | cass-operator |
| serviceaccount | cass-operator |
| secret | cass-operator-webhook-config |
| CRD | cassandradatacenters.cassandra.datastax.com |
| clusterrole | cass-operator-cluster-role |
| clusterrolebinding | cass-operator |
| role | cass-operator |
| rolebinding | cass-operator |
| service | cassandradatacenter-webhook-service |
| deployment.apps | cass-operator |
| validatingwebhookconfiguration | cassandradatacenter-webhook-registration |

In order to get the details of the above created resources, run the following command:

```bash
$ kubectl -n cass-operator describe <resource_type> <resource_name>

$ kubectl -n cass-operator get <resource_type> <resource_name> -o [yaml|json]
```

The most noticeable resource from the above list is *cassandradatacenters.cassandra.datastax.com*. Let's get the details of this resource. At the end of the output, we can see that this CRD defines a new resource type called **CassandraDataCenter** or simply **cassdc**. This new resource type is what we're going to use to create a DSE/C* cluster within a K8s cluster.

```bash
$ kubectl -n cass-operator get crd cassandradatacenters.cassandra.datastax.com -o yaml

...
status:
  acceptedNames:
    kind: CassandraDatacenter
    listKind: CassandraDatacenterList
    plural: cassandradatacenters
    shortNames:
    - cassdc
    - cassdcs
    singular: cassandradatacenter

```

As the resource type name suggests, this resource defines a DSE/C* data center (DC). 

# Define a Storage Class 

In K8s, storage dynamic provisioning is achieved through a Storage Class. For network attached storage solutions like AWS EBS, GCE Persistent Disk, Azure Disk, and etc., the storage provisioning is fully automatic. This means that we don't need to prepare the required storage space in advance; nor do we need to worry about PVs and PVCs. All these steps are automatically handled by a Storage Class (the provisioner of the Storage Class).

For local storage provisioning, it is not fully automatic. But with some help, we can make it semi-automatic. We've already explored this in another tutorial ([here](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/local_pv_sig.md)).

For the testing in this tutorial, I'm going to utilize the local storage class, named **local-storage**, that we have already created:

```bash
$ kubectl get storageclass -o wide
NAME            PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-storage   kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  21h
```

This local storage class automatically detects 3 PVs that are available in the K8s cluster (one PV per K8s node). Note that each PV has a storage capacity of 968MB.

```bash
kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
local-pv-3ca094ef   968Mi      RWO            Delete           Available           local-storage            4s
local-pv-7fce55f4   968Mi      RWO            Delete           Available           local-storage            4s
local-pv-9ef344cc   968Mi      RWO            Delete           Available           local-storage            5s
```

# Provision a DSE/C* Cluster

At this point, with a new K8s resource type *CassandraDataCenter* defined and a storage class ready, we can provision a DSE/C* cluster. 

First we need to create a resource definition file (e.g. named *mydsecluster-dc1.yaml*) for a single-DC, single-rack, 3-node DSE 6.8.1 cluster. Each DSE node requests for 4GB system memory (with 2GB as the heap size) and 400MB storage space. Please pay attention that the **storageClassName** must match what we have created in the previous step, which is ***local-storage***.

```yaml
apiVersion: cassandra.datastax.com/v1beta1
kind: CassandraDatacenter
metadata:
  name: dc1
spec:
  clusterName: mydsecluster
  serverType: dse
  serverVersion: 6.8.1
  size: 3
  racks:
  - name: rack1
  resources:
    requests:
      memory: 4Gi
  storageConfig:
    cassandraDataVolumeClaimSpec:
      storageClassName: local-storage
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 400M
  config:
    cassandra-yaml:
      num_tokens: 8
      allocate_tokens_for_local_replication_factor: 3
    jvm-server-options:
      initial_heap_size: 2G
      max_heap_size: 2G
```

Then we schedule it in the K8s cluster 

```bash
$ kubectl apply -f mydsecluster-dc1.yaml
cassandradatacenter.cassandra.datastax.com/dc1 created


```



There is minor difference between defining a DSE cluster and an OSS C* cluster. I'll cover it later in this tutorial.