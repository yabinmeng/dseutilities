# Overview

In the [previous tutorial](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/k8s_cass_operator_local.md), I explored the procedure of deploying a DSE 6.8.1 cluster on an on-prem K8s cluster with locally attached storage. In this tutorial, I'm going to explore the procedure of deploying a DSE 6.8.1 cluster on GKE cloud platform with the network attached storage spaces (GCP persistent disks). Moreover, I'm going to explore how to expose the DSE K8s "service" through an K8s Ingress for external access.

# Provision a GKE Cluster

A GKE cluster can be launched from the GCP console or from "gcloud" utility. The steps to create it from GCP console are as below:

* Cluster Basics - specify:
  * GKE cluster name,  
  * Cluster location
    * Type: zonal or regional
    * Zone name or region name
  * K8s version

![Cluster Basics](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/cluster_basics.png)

* Node pool node specification

![Node Specification](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/resources/k8s_cass_operator_gke/images/nodes_machine.type.png)