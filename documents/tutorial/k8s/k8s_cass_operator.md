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

This local storage class automatically detects 3 PVs that are available in the K8s cluster (one PV per K8s node). Note that each PV has a storage capacity of close to 4GB.

```bash
kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
local-pv-43190a99   3873Mi     RWO            Delete           Available           local-storage            13m
local-pv-77e548f1   3873Mi     RWO            Delete           Available           local-storage            12m
local-pv-b23352ed   3873Mi     RWO            Delete           Available           local-storage            13m
```

# Provision a DSE/C* Cluster

At this point, with a new K8s resource type ***CassandraDataCenter*** defined and a storage class ready, we can provision a DSE/C* cluster. 

First we need to create a resource definition file that defines a DSE/C* DC. An example (e.g. named *mydsecluster-dc1.yaml*) is demonstrated below. **Note** that in this resource definition file. The settings in this resource definition file are quite straightforward and self-explanatory. But I'd like to emphasize a few things:

* Both DSE/C* cluster name (***spec.clusterName***) and DC name (***metadata.name***) must be lower case
* DSE/C* version (***spec.serverType***)
  *  for DSE cluster, the value is **dse** 
  *  for OSS C* cluster, the value is **cassandra**
* DSE/C* version - at the moment, the only supported versions are:
  * for DSE cluster, 6.8.0 and 6.8.1
  * for OSS C* cluster, 3.11.6
* The Storage Class (***spec.storageConfig.cassandraDataVolumeClaimSpec.storageClassName***) value must match what we have created in the previous step (e.g. ***local-storage***).
* DSE/C* JVM options, note the config. name differences (with or without "server"). If we misuse the incorrect name (e.g. "jvm_options" for a DSE cluster), the DSE/C* Pods will fail to be launched
  * for DSE clusters, the JVM options are defined under ***spec.config.jvm_server_options***
  * for OSS C* clusters, the JVM options are defined under ***spec.config.jvm_options***

```yaml
apiVersion: cassandra.datastax.com/v1beta1
kind: CassandraDatacenter
metadata:
  name: dc1
spec:
  clusterName: mydsecluster
  serverType: dse
  serverVersion: 6.8.1
  managementApiAuth:
    insecure: {}
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
          storage: 1Gi
  config:
    cassandra-yaml:
      num_tokens: 8
      allocate_tokens_for_local_replication_factor: 3
      authenticator: com.datastax.bdp.cassandra.auth.DseAuthenticator
      authorizer: com.datastax.bdp.cassandra.auth.DseAuthorizer
      role_manager: com.datastax.bdp.cassandra.auth.DseRoleManager
    dse-yaml:
      authentication_options:
        enabled: true
        default_scheme: internal
    jvm-server-options:
      initial_heap_size: 2G
      max_heap_size: 2G
```

We launch the ***CassandraDatacenter*** K8s object via the following command:
```bash
$ kubectl -n cass-operator create -f myclusterdc1.yaml
cassandradatacenter.cassandra.datastax.com/dc1 created
```

We should also see a number (***spec.size***) of DSE/C* node Pods are launched. Each Pod has a naming convention of ***<dse/C_cluster_name>-<DC_name>-<rack_name>-sts-#***. For a successful provisioning, you should see all DSE/C* node Pods in "Running" status. If there are not enough DSE/C* Pods as per ***spec.size***, or the Pods are not in "Running" status, there are some issues with the provisioning
```bash
$ kubectl -n cass-operator get pods
NAME                             READY   STATUS    RESTARTS   AGE
cass-operator-78c9999797-vrq8z   1/1     Running   0          12h
mydsecluster-dc1-rack1-sts-0     2/2     Running   0          15m
mydsecluster-dc1-rack1-sts-1     2/2     Running   0          15m
mydsecluster-dc1-rack1-sts-2     2/2     Running   0          15m
```

Behind the scene, the DSE/C* Pods and the corresponding Persistent Volume Claims (PVCs) are managed by a number of StatefulSets (one StatefulSet per rack) that were created by the ***CassandraDatacenter*** CRD. These StatefulSets (STSs) have the naming convention of ***<dse/C_cluster_name>-<DC_name>-<rack_name>_sts***

In my testing, there is only one rack and therefore one STS. Checking the details of the StatefulSet will show us key information like how many replicas are maintained by the STS, the volume claim and the associated StorageClass, and etc.

```bash
$ kubectl -n cass-operator get sts
NAME                         READY   AGE
mydsecluster-dc1-rack1-sts   3/3     39m

$ kubectl -n cass-operator describe sts mydsecluster-dc1-rack1-sts
Name:               mydsecluster-dc1-rack1-sts
...
Replicas:           3 desired | 3 total
Update Strategy:    RollingUpdate
  Partition:        824636451024
Pods Status:        3 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
...
Volume Claims:
  Name:          server-data
  StorageClass:  local-storage
...
Events:
  Type    Reason            Age   From                    Message
  ----    ------            ----  ----                    -------
  Normal  SuccessfulCreate  46m   statefulset-controller  create Claim server-data-mydsecluster-dc1-rack1-sts-0 Pod mydsecluster-dc1-rack1-sts-0 in StatefulSet mydsecluster-dc1-rack1-sts success
  Normal  SuccessfulCreate  46m   statefulset-controller  create Pod mydsecluster-dc1-rack1-sts-0 in StatefulSet mydsecluster-dc1-rack1-sts successful
  Normal  SuccessfulCreate  46m   statefulset-controller  create Claim server-data-mydsecluster-dc1-rack1-sts-1 Pod mydsecluster-dc1-rack1-sts-1 in StatefulSet mydsecluster-dc1-rack1-sts success
  Normal  SuccessfulCreate  46m   statefulset-controller  create Pod mydsecluster-dc1-rack1-sts-1 in StatefulSet mydsecluster-dc1-rack1-sts successful
  Normal  SuccessfulCreate  46m   statefulset-controller  create Claim server-data-mydsecluster-dc1-rack1-sts-2 Pod mydsecluster-dc1-rack1-sts-2 in StatefulSet mydsecluster-dc1-rack1-sts success
  Normal  SuccessfulCreate  46m   statefulset-controller  create Pod mydsecluster-dc1-rack1-sts-2 in StatefulSet mydsecluster-dc1-rack1-sts successful  
```

From the event associated with the STS, we can see that in sequence it creates one DSE/C* Pod followed by a corresponding PVC for that Pod, until the number of replicas maintained in the STS is reached.