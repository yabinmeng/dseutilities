# 1. Overview

In the [previous tutorial](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/k8s_cass_operator_local.md), I explored the procedure of deploying a DSE 6.8.1 cluster on an on-prem K8s cluster with locally attached storage. In this tutorial, I'm going to explore the procedure of deploying a DSE 6.8.1 cluster on GKE cloud platform with the network attached storage spaces (GCP persistent disks). Moreover, I'm going to explore how to expose the DSE K8s "service" through an K8s Ingress for external access.

# 2. Provision a GKE Cluster

A GKE cluster can be launched from the GCP console or from "gcloud" utility. The steps to create it from GCP console are as below:

* In the "Cluster Basics" page, specify the following key information:
  * GKE cluster name,  
  * Cluster location
    * Type: zonal or regional
    * Zone name or region name
  * K8s version (as of the writing, the latest GKE K8s version is 1.16.10-gke.8)
  
<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/cluster_basics.png" alt="Cluster Basics" width="500"/>

* In the "NODE POOLs --> default-pool" page, specify the following key information
  * The size (the number of nodes) of the K8s cluster 
  * Whether we want GKE to auto-scale the cluster when needed

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/default-pool.png" alt="default-pool" width="500"/>

* In the "NODE POOLs --> default-pool --> Nodes" page, specify the following key information
  * GCE instance type (in this tutorial, the instance type is **n1-standard-4**)
    * **NOTE** make sure the selected instance type is big enough to run DSE server. Otherwise, K8s probably won't be able to schedule starting a DSE node Pod successfully
  * GCE instance boot disk type and size

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/nodes_machine.type.png" alt="default-pool:Nodes" width="500"/>

* In the "NODE POOLs --> default-pool --> Security" page, specify the following key information
  * Choose the GCP service account that is allowed to access the GCE instances 
    * **NOTE** that this is GCP service account, not K8s service account. As a GCP security best practice, it is highly recommended NOT to use "Compute Engine default service account".

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/security_service.account.png" alt="default-pool:Nodes" width="500"/>


Leave the values on other pages as default and then click "Create" button. Wait for a short while and you'll see the created GKE cluster showing up in the cluster list.

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/gke_cluster_list.png" alt="default-pool:Nodes" width="500"/>


# 3. Access the GKE Cluster from Client PC

## 3.1. Install Google Cloud SDK

The easiest way to access GCP resources, including a GKE cluster is through Google Cloud SDK. Please follow the Google document to install and configure Google Cloud SDK on your client PC. Please choose the corresponding procedure that matches your client PC OS

https://cloud.google.com/sdk/docs/quickstarts

## 3.2. Connect to GKE Cluster

In order to connect to the GKE cluster from the client PC, we need to log in GCP first. Run the following command and follow the instructions. 

```bash
$ gcloud auth login
```

After logging in, verify the GCP login info using either of the following command. Make sure the GCP project, account, and region/zone information matches the desired ones.

```bash
$ gcloud info
$ gcloud config list
```

If the GCP login information is correct, we can connect to the GKE cluster using the following command. This command generates the credentials and endpoint information that are need by the "kubectl" utility to connect to a specific cluster in GKE. By default, the credentials and endpoint information is stored in "***~/.kube/config***" file. 

```bash
$ gcloud container clusters get-credentials <gke_cluster_name> --zone <zone_name> --project <GCP_project_name>
Fetching cluster endpoint and auth data.
kubeconfig entry generated for <gke_cluster_name>
```

At this point, we're ready to run operate the GKE cluster from the client PC. This assumes that "kubectl" utility is already installed on the client PC. If not, follow K8s document ([here](https://kubernetes.io/docs/tasks/tools/install-kubectl/)) to install it. Once installed, verify its version and the basic GKE cluster information using the following commands:

```bash
// "kubectl" version
$ kubectl version --client

// GKE cluster information
$ kubectl cluster-info
```

We can also get the GKE cluster (worker) node information using the following command. Please **NOTE** that the node listed here are ALL worker nodes. For a GKE cluster, a master node is managed by Google and you can only access it through APIs.

```bash
$ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE     VERSION
gke-ymtest-ck8s-operator-default-pool-5f7a5097-7b2h   Ready    <none>   4h47m   v1.16.10-gke.8
gke-ymtest-ck8s-operator-default-pool-5f7a5097-8qlh   Ready    <none>   4h47m   v1.16.10-gke.8
gke-ymtest-ck8s-operator-default-pool-5f7a5097-glgm   Ready    <none>   4h47m   v1.16.10-gke.8
```

# 4. Install DSE Cluster using C* Operator

Now since we have a running GKE cluster and we're able to connect it from the client PC, we're good to deploy a DSE cluster in it using C* Operator. Like what we did in an on-prem K8s cluster, the high-level procedure is as below:

* Define a storage class (which is responsible for providing the storage space to be associated with each DSE server Pod)
* Install C* Operator (CRD) in the K8s(GKE) cluster
* Deploy the DSE cluster using "CassandraDC" resource type (created by C* Operator)

## 4.1. Define a Storage Class

As we've already discussed in the [previous tutorial](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/k8s_cass_operator_local.md), a K8s Storage Class that corresponds to network attached storage solutions from different cloud providers like AWS EBS, GCE Persistent Disk, Azure Disk, and etc., is able to completely provision the storage space dyanmically. For GKE, the Storage Class provisioner is [**GCE PD**](https://kubernetes.io/docs/concepts/storage/storage-classes/#gce-pd).

In this tutorial, I'm going to define a Storage Class named "server-storage" with the following specification ("sever_storage_sc.yaml"):

```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: server-storage
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  fstype: xfs
  replication-type: none
```

From the specification, Google persistent SSD disk is going to be used as the storage space for the GKE cluster. Considering the main user case for this GKE cluster is to deploy a DSE cluster in it, I'm using "xfs" file system on the provisioned storage space (instead of the default "ext4" file system). This is because "xfs" file system is the recommended one for DSE/C* cluster.

```bash
$ kubectl apply -f server_storage_sc.yaml
```

## 4.2. Install C* Operator

This step is exactly the same as that in the previous tutorial

```bash
kubectl apply -f https://raw.githubusercontent.com/datastax/cass-operator/v1.3.0/docs/user/cass-operator-manifests-v1.16.yaml
namespace/cass-operator created
```

## 4.3. Deploy a DSE 6.8.1 Cluster

Again, this step is almost identical to that in the previous tutorial. We create a resource definition file for the CassandraDC type ("mydsecluster.yaml"). 

```bash
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
      storageClassName: server-storage
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 2Gi
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

The only difference is the "storageClassName" is changed to the new Storage Class name, **server-storage**, as we created earlier.

```bash
kubectl -n cass-operator apply -f mydsecluster.yaml
```

## 4.4. Troubleshooting - DSE Pods Failing to be Initialied 

From the previous CassandraDC resource definition file, each Pod requires 4G memory. If we provision the GKE cluster with a smaller GCE instance type (e.g. default "n1-standard-1"), then K8s won't be able to satisfy the Pod request and therefore it will fail launching (scheduling) DSE Pods on the GKE nodes.

```bash
$ kubectl -n cass-operator get pods
NAME                             READY   STATUS     RESTARTS   AGE
cass-operator-78c9999797-pdmmh   1/1     Running    0          14m
mydsecluster-dc1-rack1-sts-0     0/2     Init:0/1   0          13m
mydsecluster-dc1-rack1-sts-1     0/2     Init:0/1   0          13m
mydsecluster-dc1-rack1-sts-2     0/2     Init:0/1   0          13m
```

In this tutorial, the GKE node instance type is **n1-standard-4** and it has enough system resource to satisfy the Pod request. But the DSE Pod initialization still gets stuck in the above status. Why is this?




When I describe the DSE Pod detail as below, I found the following warning message which says "xfs" file system is not supported while K8s is trying to mount the storage request (**PVC**) to the the Pod.

```bash
$ kubectl -n cass-operator describe pod mydsecluster-dc1-rack1-sts-0
  ... ... 
  Warning  FailedMount  2m7s (x2 over 4m21s)  kubelet, gke-ymtest-operator-default-pool-d0e13daf-kk5w  Unable to attach or mount volumes: unmounted volumes=[server-data], unattached volumes=[server-config default-token-vq8tc server-logs server-data]: timed out waiting for the condition
  Warning  FailedMount  115s (x2 over 3m58s)  kubelet, gke-ymtest-operator-default-pool-d0e13daf-kk5w  (combined from similar events): MountVolume.MountDevice failed for volume "pvc-9a84fce4-ab0a-4225-a640-275b439ba5f8" : mount failed: exit status 32
Mounting command: systemd-run
Mounting arguments: --description=Kubernetes transient mount for /var/lib/kubelet/plugins/kubernetes.io/gce-pd/mounts/gke-ymtest-operator-46-pvc-9a84fce4-ab0a-4225-a640-275b439ba5f8 --scope -- mount -t xfs -o defaults /dev/disk/by-id/google-gke-ymtest-operator-46-pvc-9a84fce4-ab0a-4225-a640-275b439ba5f8 /var/lib/kubelet/plugins/kubernetes.io/gce-pd/mounts/gke-ymtest-operator-46-pvc-9a84fce4-ab0a-4225-a640-275b439ba5f8
Output: Running scope as unit: run-r1dcc3bb559e74f86a16e26380232fc31.scope
mount: /var/lib/kubelet/plugins/kubernetes.io/gce-pd/mounts/gke-ymtest-operator-46-pvc-9a84fce4-ab0a-4225-a640-275b439ba5f8: unknown filesystem type 'xfs'.
```

It turns out that the default GKE cluster OS image is "Container Optimized OS - cos" has some limitations related with using XFS. Although there is a [work-around](https://medium.com/@allanlei/mounting-xfs-on-gke-adcf9bd0f212), a cleaner way is to change the GKE OS image from "cos" to another one that supports XFS (eg. Ubuntu). This requires we need to recreate a GKE cluster. This time, we need to choose the right image type in the "NODE POOLs --> default-pool --> Nodes" page.

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/nodes_os_ubuntu.png" alt="default-pool:Nodes" width="500"/>


## 4.5. Verify Deployed DSE Cluster

Once we launched the GKE cluster with the right instance type and OS image. The DSE server Pods are launched successfully and we can verify the connection to it from CQLSH utility from within a DSE Pod (actually the main container, "cassandra", within the Pod).

```bash
$ kubectl -n cass-operator get pods
NAME                             READY   STATUS    RESTARTS   AGE
cass-operator-78c9999797-kqm6w   1/1     Running   0          10m
mydsecluster-dc1-rack1-sts-0     2/2     Running   0          10m
mydsecluster-dc1-rack1-sts-1     2/2     Running   0          10m
mydsecluster-dc1-rack1-sts-2     2/2     Running   0          10m

// NOTE: this requis "jq" utility installed on the client PC
$ CASS_USER=$(kubectl -n cass-operator get secret mydsecluster-superuser -o json | jq -r '.data.username' | base64 --decode)
$ CASS_PASS=$(kubectl -n cass-operator get secret mydsecluster-superuser -o json | jq -r '.data.password' | base64 --decode)
$ kubectl -n cass-operator exec -it mydsecluster-dc1-rack1-sts-0 -c cassandra -- sh -c "cqlsh -u '$CASS_USER' -p '$CASS_PASS'"
Connected to mydsecluster at 127.0.0.1:9042.
[cqlsh 6.8.0 | DSE 6.8.1 | CQL spec 3.4.5 | DSE protocol v2]
Use HELP for help.
mydsecluster-superuser@cqlsh>
```

# 5. External Access to the DSE Cluster (Outside the GKE Cluster)

