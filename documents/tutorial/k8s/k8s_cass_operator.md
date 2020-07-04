# Overiew

Earlier this year on Mar. 31, DataStax has announced the [release](https://www.datastax.com/press-release/datastax-helps-apache-cassandra-become-industry-standard-scale-out-cloud-native-data) of open-source K8s operator for C*. Later this year on April 7th, DataStax also GA-released DataStax Enterprise (DSE) version 6.8 and K8s operator is part of this release. 

In this tutorial, I'm going to demonstrate how to provision a DSE cluster on the K8s cluster (here) and the local storage Persistent Volumes (PVs) that we created earlier ([K8s cluster](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/kubeadm_install.md) and [Local PVs](https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/k8s/local_pv_sig.md)).