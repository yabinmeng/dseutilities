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
  
<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/cluster_basics.png" alt="Cluster Basics" width="400"/>

* In the "NODE POOLs --> default-pool" page, specify the following key information
  * The size (the number of nodes) of the K8s cluster 
  * Whether we want GKE to auto-scale the cluster when needed

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/default-pool.png" alt="default-pool" width="400"/>

* In the "NODE POOLs --> default-pool --> Nodes" page, specify the following key information
  * GCE instance type (in this tutorial, the instance type is **n1-standard-4**)
    * **NOTE** make sure the selected instance type is big enough to run DSE server. Otherwise, K8s probably won't be able to schedule starting a DSE node Pod successfully
  * GCE instance boot disk type and size

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/nodes_machine.type.png" alt="default-pool:Nodes" width="400"/>

* In the "NODE POOLs --> default-pool --> Security" page, specify the following key information
  * Choose the GCP service account that is allowed to access the GCE instances 
    * **NOTE** that this is GCP service account, not K8s service account. As a GCP security best practice, it is highly recommended NOT to use the default "Compute Engine default service account". Instead, we should create a new GCP service account and grant it proper privileges.

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/security_service.account.png" alt="default-pool:Nodes" width="400"/>


Leave the values on other pages as default and then click "Create" button. Wait for a short while and you'll see the created GKE cluster showing up in the cluster list.

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/gke_cluster_list.png" alt="default-pool:Nodes" width="400"/>


# 3. Access the GKE Cluster from Client PC

## 3.1. Install Google Cloud SDK

The easiest way to access GCP resources, including a GKE cluster is through Google Cloud SDK. Please follow the Google document to install and configure Google Cloud SDK on your client PC. Please choose the corresponding procedure that matches your client PC OS

https://cloud.google.com/sdk/docs/quickstarts

## 3.2. Connect to GKE Cluster

In order to connect to the GKE cluster from the client PC, we need to log in GCP first. Run the following command and follow the instructions. **NOTE**: Check Appendix A for another way of connecting to GCP using a dedicated service account!

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
NAME                                                  STATUS   ROLES    AGE    VERSION
gke-ymtest-ck8s-operator-default-pool-02df0734-90z0   Ready    <none>   173m   v1.16.10-gke.8
gke-ymtest-ck8s-operator-default-pool-02df0734-b12z   Ready    <none>   173m   v1.16.10-gke.8
gke-ymtest-ck8s-operator-default-pool-02df0734-gwfv   Ready    <none>   173m   v1.16.10-gke.8
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
$ kubectl apply -f https://raw.githubusercontent.com/datastax/cass-operator/v1.3.0/docs/user/cass-operator-manifests-v1.16.yaml
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

It turns out that the default GKE cluster OS image is "Container Optimized OS - cos" has some limitations related with using XFS. Although there is a [work-around](https://medium.com/@allanlei/mounting-xfs-on-gke-adcf9bd0f212), a cleaner way is to change the GKE OS image from "cos" to another one that supports XFS (eg. Ubuntu). This requires we recreate a GKE cluster. This time, we need to choose the right OS image type ("Ubuntu") in the "NODE POOLs --> default-pool --> Nodes" page.

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/nodes_os_ubuntu.png" alt="default-pool:Nodes" width="400"/>


## 4.5. Verify Deployed DSE Cluster

Once we launched the GKE cluster with the right instance type and OS image, the DSE server Pods are launched successfully and we can verify the connection to it from CQLSH utility from within a DSE Pod (actually from within the main container, "cassandra", within the Pod).

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

So far we successfully deployed a DSE cluster in a GKE K8s cluster. Now let's see how to connect to the DSE cluster from outside the GKE cluster (e.g. from the client PC).

First of all, the GKE cluster we created above is a public cluster. That means each K8s worker node in the cluster has a public IP address. We can get their public IPs of the GKE worker nodes (GCE instances) by specifying "-o wide" option for "kubectl get nodes" command:

```bash
$ kubectl get nodes -o wide
NAME                                                  STATUS   ROLES    AGE    VERSION          INTERNAL-IP   EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
gke-ymtest-ck8s-operator-default-pool-02df0734-90z0   Ready    <none>   173m   v1.16.10-gke.8   10.128.0.12   xx.xxx.xxx.xx     Ubuntu 18.04.4 LTS   5.3.0-1016-gke   docker://19.3.2
gke-ymtest-ck8s-operator-default-pool-02df0734-b12z   Ready    <none>   173m   v1.16.10-gke.8   10.128.0.10   xxx.xxx.xxx.xxx   Ubuntu 18.04.4 LTS   5.3.0-1016-gke   docker://19.3.2
gke-ymtest-ck8s-operator-default-pool-02df0734-gwfv   Ready    <none>   173m   v1.16.10-gke.8   10.128.0.11   xx.xxx.xxx.xx    Ubuntu 18.04.4 LTS   5.3.0-1016-gke   docker://19.3.2
```

In a K8s cluster, the way to allow for external access is through [K8s Services](https://kubernetes.io/docs/concepts/services-networking/service/). There are various types of K8s services but not all are suitable for exposing DSE cluster externally. In this tutorial, I'm demonstrating using K8s [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport) service to allow external access to the DSE cluster in the GKE cluster.

## 5.1. Use K8s "NodePort" Service to Expose "DSE" Service

---

**NOTE** using "NodePort" to expose K8s service externally is NOT recommended for production deployment because this method is closely tied up with the IP addresses of the Pods deployed in the K8s cluster; and on a particular port which has to be within the range 30000 to 32767. It is therefore a fairly static solution with some limitations. 

---

Let's file create a NodePort service definition file ("dseext_nodeport.yaml") .

```bash
apiVersion: v1
kind: Service
metadata:
  name: dseextsvc
spec:
  type: NodePort
  selector:
    cassandra.datastax.com/cluster: mydsecluster
  ports:
  - port: 9042
    protocol: TCP
    targetPort: 9042
```

Create the NodePort service named *dseextsvc*

```bash
$ kubectl -n cass-operator apply -f dseext_nodeport.yaml
service/dseextsvc created

$ kubectl -n cass-operator describe service dseextsvc
Name:                     dseextsvc
Namespace:                cass-operator
Labels:                   <none>
Annotations:              kubectl.kubernetes.io/last-applied-configuration:
                            {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"dseextsvc","namespace":"cass-operator"},"spec":{"ports":[{"port":...
Selector:                 cassandra.datastax.com/cluster=mydsecluster
Type:                     NodePort
IP:                       10.12.0.187
Port:                     <unset>  9042/TCP
TargetPort:               9042/TCP
NodePort:                 <unset>  30278/TCP
Endpoints:                10.8.0.5:9042,10.8.1.9:9042,10.8.2.3:9042
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

Checking the created service detail and we can see that a random port (30278) has been assigned for external access, which also maps to an internal port of 9042 on each DSE node container.

## 5.2. Create a GCP Firewall Rule to Allow External Access to NodePort

In order for us to access GCP instances from outside, we need to first create a firewall that allows us to do so. The firewall rule we created below allows external access to *ALL* GCE instances (within the current GCP project) on port 30278 (and port 23 for telnet verification purpose) from one specific IP address (which is the client PC's IP address).

```bash
$ gcloud compute firewall-rules create dseextsvc-node-port --source-ranges=<client_PC_IP>/32 --allow tcp:30278,tcp:23
Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/<GCP_project_name>/global/firewalls/dseextsvc-node-port].
Creating firewall...done.
NAME                 NETWORK  DIRECTION  PRIORITY  ALLOW             DENY  DISABLED
dseextsvc-node-port  default  INGRESS    1000      tcp:30278,tcp:23        False
```

**NOTE** We can also limit the firewall rule to only allow external access to a specific set of target GCE instances, e.g. those GCE instances as the GKE cluster worker nodes. We can achieve this by creating a dedicated service account (see Appendix) and add the following condition when creating the firewall rule.

```bash
--target-service-accounts=<service_account_full_name>
(e.g. --target-service-accounts=mydse-k8s-svcacct@<GCP_project_name>.iam.gserviceaccount.com)
```

## 5.3. Verify CQLSH Connection from the Client PC

Now we can test the connection from the client PC using "CQLSH" utility. **NOTE** that we have to specify the exposed NodePort at 30278 instead of the regular 9042.

```bash
$ cqlsh <GKE_Worker_node_Public_IP> 30278 -u $CASS_USER -p $CASS_PASS
Connected to mydsecluster at 34.69.152.80:30278.
[cqlsh 5.0.1 | DSE 6.8.1 | CQL spec 3.4.5 | DSE protocol v2]
Use HELP for help.
mydsecluster-superuser@cqlsh> desc keyspaces;

system_virtual_schema  system_schema  system_backups      dse_insights_local
dse_system_local       system_auth    dse_insights        dse_system
dse_security           system_views   system_distributed
solr_admin             system         system_traces
testks                 dse_leases     dse_perf

```

# 6. Appendix. Manage GKE Cluster with Dedicated GCP Service Account for Better Security

In the above procedure, when we create the GKE cluster, In the "NODE POOLS --> default-pool --> Security" page, we choose the default "Compute Engine default service account" as the GCP service account that is used to access the GCE instances (as K8s worker nodes).

As already mentioned, this is not a GCP security best practice, we should always use a dedicated GCP service account with fine-grained access privileges. In this Appendix, I will describe how to do so.

## 6.1. Create a GCP Service Account

From "GCP IAM & Admin --> Service Accounts" page, click "Create Service Account" and follows the instructions. In this tutorial, a service account named "mydse-k8s-svcacct" is given (the full GCP service account is **<given_name>@<GCP_project_name>.iam.gserviceaccount.com**). For this service account, the following roles are granted:
* Compute Admin
* Kubernetes Engine Admin 

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/gcp_k8s_svcacct.png" width="400"/>

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/gcp_k8s_svcacct_role.png" width="400"/>


Please **NOTE** that in a real deployment, a service account as above may likely be given too much permissions than it should have. For example, we probably should at least to separate the GCE instances and GKE cluster access and management privileges into different service accounts and/or user groups. 

Once the service account is created, click its name from the service account list, which brings up the service account detail page. Since we're going to use this service account to manage a GKE cluster from a client machine, we need to add a key for this service account. With this key, we're able to connect to the GCP environment using this service account.

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/gke_k8s_svcacct_addkey.png" width="400"/>

Follow the instructions on the page. Choose JSON as the key type and create the key. Once created, it automatically reminds to download the generated key (in json format), e.g. <GCP_project_name>-33be509e87d0.json.

## 6.2. Connect using the GCP Service Account

After we downloaded the GCP service account key to the client machine, we can use it to connect the client PC to the GCP project.

```bash
$ gcloud auth activate-service-account mydse-k8s-svcacct@<GCP_project_name>.iam.gserviceaccount.com --key-file=<service_account_key_file_name>.json --project=<GCP_project_name>
Activated service account credentials for: [mydse-k8s-svcacct@<GCP_project_name>.iam.gserviceaccount.com]

$ gcloud config list
[core]
account = mydse-k8s-svcacct@<GCP_project_name>.iam.gserviceaccount.com
disable_usage_reporting = True
project = <GCP_project_name>

Your active configuration is: [default]
```

Since this GCP service account has GKE Admin privilege, we can use it to manage the GKE cluster (after connecting to the GKE cluster first). For example, we can install C* Operator CRD and deploy a DSE cluster in the GKE cluster, just as we did above. 

```bash
$ gcloud container clusters get-credentials ymtest-ck8s-operator --zone us-central1-c --project <GCP_project_name>
Fetching cluster endpoint and auth data.
kubeconfig entry generated for ymtest-ck8s-operator.

$ kubectl cluster-info
Kubernetes master is running at https://xx.xxx.xxx.xx
GLBCDefaultBackend is running at https://xx.xxx.xxx.xx/api/v1/namespaces/kube-system/services/default-http-backend:http/proxy
KubeDNS is running at https://xx.xxx.xxx.xx/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://xx.xxx.xxx.xx/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```