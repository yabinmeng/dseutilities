# 1. Overview

[DataStax Enterprise (DSE) Metrics Collector](https://docs.datastax.com/en/monitoring/doc/monitoring/opsUseMetricsCollector.html) is a relatively new monitoring solution from DataStax that is used to monitor DSE cluster metrics (including OS metrics). It is part of DSE software package and was introduced in DSE verion 6.7 (enabled by default) and backported on DSE 6.0.5+ and DSE 5.1.14+ (disabled by default).

DSE Metrics Collector (DSE MC) is based on [collectd](https://collectd.org/) and works as a sub-process spawned by DSE JVM and its life cycle is managed by DSE.

Please **NOTE** that DSE MC is not a complete monitoring solution by itself. It simply simplifies the collection of DSE metrics in a standard, high performing way, and without the need to install an agent on DSE servers (aka, agent-less metrics collection). The collected metrics need to be exported to other dedicated  monitoring systems such as [Prometheus](https://prometheus.io/), [Graphite](https://graphiteapp.org/), and etc. for metrics viewing, dashboard-ing, and so on. 

The official DataStax document of how to use DSE MC can be found from [here](https://docs.datastax.com/en/monitoring/doc/monitoring/opsUseMetricsCollector.html).

## 1.1. Integrate DSE MC with Prometheus and Grafana

The combination of Prometheus and [Grafana](https://grafana.com/) is a very popular choice as a monitoring solution. DataStax has provided a complete example [repository](https://github.com/datastax/dse-metric-reporter-dashboards) to help simplify the integration of DSE MC with Prometheus and Grafana, especially with the following ways:

* Ready-to-use Prometheus and Grafana docker containers that are deployable through docker-compose.
* Configuration templates for collecting DSE MC metrics from a DSE cluster
* A full suite of pre-built Grafana dashboards to view DSE server and OS metrics of a DSE cluster.

## 1.2. Automate the Integration 

Although DataStax has already simplified the integration of DSE MC with Prometheus and Grafna, the [procedure](https://docs.datastax.com/en/monitoring/doc/monitoring/metricsCollector/mcExportMetricsDocker.html) still has some manual work involved. For example,

* We still need to install docker and docker compose on the host machine where we intend to run Prometheus and Grafana (assuming we don't have existing Prometheus and Grafana servers)
* We still need to configure "collectd" and DSE MC on each of DSE servers.
* We still need to adjust Prometheus configuration per DSE cluster so it can monitor all DSE nodes within the cluster.

The Ansible playbook in this repository aims to automate the DSE MC integration procedure with (container based) Prometheus and Grafana servers. All the above mentioned manual steps are taken care of and the Ansible playbook is also able to automatically detect and configure almost all DSE cluster specific information (e.g. DSE cluster name; DSE node IP list).

### 1.2.1. Usage

#### 1.2.1.1. **hosts** file 

In order to monitor a specific DSE cluster, we need to first update the **hosts** by adding the proper host machine IP(s) under the two categories: 
* *[dse_server]*: the list of IPs of the DSE servers in the cluster 
* *[metrics_server]*: the host machine IP where the Prometheus and Grafana servers are running

```bash
[dse_server]
<DSE_Node_IP_1>
<DSE_Node_IP_2>
<DSE_Node_IP_3>
...

[metrics_server]
<Prometheus_and_Grafana_Host_IP>
```

#### 1.2.1.2. Global Variables



#### 1.2.1.3. Executing the Script

Running the Ansible playbook is simple, as below. Please make sure the required SSH access (with sudo privilege) for Ansible execution is pre-configured properly.

```bash
ansible-playbook -i ./hosts dse_metrics_collector.yaml --private-key <ssh_private_key> -u <ssh_user>
```

Once the Ansible playbook is successfully executed, you can view a plethera of DSE cluster metrics from pre-built Grafana dashboards by accessing the following address:

```bash
http://<Prometheus_and_Grafana_Host_IP>:3000
```
