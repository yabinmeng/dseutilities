# Overiew

Earlier this year on Mar. 31, DataStax has announced the [release](https://www.datastax.com/press-release/datastax-helps-apache-cassandra-become-industry-standard-scale-out-cloud-native-data) of K8s operator for Apache C*. Later this year on April 7th, DataStax also GA-released DataStax Enterprise (DSE) version 6.8 and K8s operator is part of this release. For simplicity purpose, I'm going to use the term "C* Operator" to refer to K8s operator for Apache C* and DSE.   

In this tutorial, I will demonstrate how to provision a DSE cluster (through C* Operator) on the K8s cluster and the local storage Persistent Volumes (PVs) that we created earlier ([K8s cluster](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/kubeadm_install.md) and [Local PVs](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/local_pv_sig.md)). 


Note that K8s cluster has 3 nodes and the master node is configured to allow launching Pods on it.

```bash
$ kubectl get nodes
NAME                                     STATUS   ROLES    AGE     VERSION
ip-10-101-32-187.srv101.dsinternal.org   Ready    <none>   4h15m   v1.17.6
ip-10-101-32-217.srv101.dsinternal.org   Ready    <none>   4h15m   v1.17.6
ip-10-101-35-135.srv101.dsinternal.org   Ready    master   4h19m   v1.17.6
```

The local PVs that are available in the cluster are as below:

```bash
kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
local-pv-3ca094ef   968Mi      RWO            Delete           Available           local-storage            4s
local-pv-7fce55f4   968Mi      RWO            Delete           Available           local-storage            4s
local-pv-9ef344cc   968Mi      RWO            Delete           Available           local-storage            5s
```

# Install C* Operator

At the core of C* Operator, it is an API extension of K8s through [Customer Resource Definition (CRD)](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/). Currently it supports K8s versions from 1.13 to 1.18 (1.15 and above is recommended). The corresponding CRDs can be found from [here] (https://github.com/datastax/cass-operator).

In my testing, the procedure of installing C* Operator (version 1.17) is as below (executed from K8s master node):

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
