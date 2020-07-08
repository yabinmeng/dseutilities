# Overview

In the [previous tutorial](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/k8s_cass_operator_local.md), I explored the procedure of deploying a DSE 6.8.1 cluster on an on-prem K8s cluster with locally attached storage. In this tutorial, I'm going to explore the procedure of deploying a DSE 6.8.1 cluster on GKE cloud platform with the network attached storage spaces (GCP persistent disks). Moreover, I'm going to explore how to expose the DSE K8s "service" through an K8s Ingress for external access.

# Provision a GKE Cluster

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
  * GCE instance type 
    * **NOTE** make sure the selected instance type is big enough to run DSE server. Otherwise, K8s probably won't be able to schedule starting a DSE node Pod successfully
  * GCE instance boot disk type and size

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/nodes_machine.type.png" alt="default-pool:Nodes" width="500"/>

* In the "NODE POOLs --> default-pool --> Security" page, specify the following key information
  * Choose the GCP service account that is allowed to access the GCE instances 
    * **NOTE** that this is GCP service account, not K8s service account. As a GCP security best practice, it is highly recommended NOT to use "Compute Engine default service account".

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/security_service.account.png" alt="default-pool:Nodes" width="500"/>


Leave the values on other pages as default and then click "Create" button. Wait for a short while and you'll see the created GKE cluster showing up in the cluster list.

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/gke_cluster_list.png" alt="default-pool:Nodes" width="500"/>


# Access the GKE Cluster from Client PC

## Install Google Cloud SDK

The easiest way to access GCP resources, including a GKE cluster is through Google Cloud SDK. Please follow the Google document to install and configure Google Cloud SDK on your client PC. Please choose the corresponding procedure that matches your client PC OS

https://cloud.google.com/sdk/docs/quickstarts

Once the the Google Cloud SDK is installed and configured on the client PC, verify its information using the following command. Make sure the GCP project and account information matches your desired ones.

```bash
$ gcloud info
```

## Connect to GKE Cluster

In order to run the 