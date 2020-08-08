# Background

[DataStax Enterprise (DSE) Metrics Collector](https://docs.datastax.com/en/monitoring/doc/monitoring/opsUseMetricsCollector.html) is a relatively new monitoring solution from DataStax that is used to monitor DSE cluster metrics (including OS metrics). It is part of DSE software package and was introduced in DSE verion 6.7 (enabled by default) and backported on DSE 6.0.5+ and DSE 5.1.14+ (disabled by default).

DSE Metrics Collector (DSE MC) is based on [collectd](https://collectd.org/) and works as a sub-process spawned by DSE JVM and its life cycle is managed by DSE.

Please **NOTE** that DSE MC is not a complete monitoring solution by itself. It simply simplifies the collection of DSE metrics in a standard, high performing way, and without the need to install an agent on DSE servers (aka, agent-less metrics collection). The collected metrics need to be exported to other dedicated  monitoring systems such as [Prometheus](https://prometheus.io/), [Graphite](https://graphiteapp.org/), and etc. for metrics viewing, dashboard-ing, and so on. 

The official DataStax document of how to use DSE MC can be found from [here](https://docs.datastax.com/en/monitoring/doc/monitoring/opsUseMetricsCollector.html).

## Integrate DSE MC with Prometheus and Grafana

The combination of Prometheus and [Grafana](https://grafana.com/) is a very popular choice as a monitoring solution. DataStax has provided a complete example [repository](https://github.com/datastax/dse-metric-reporter-dashboards) to help simplify the integration of DSE MC with Prometheus and Grafana, especially with the following ways:

* Ready-to-use Prometheus and Grafana docker containers with docker-compose.
* Configuration templates for collecting DSE MC metrics from a DSE cluster
* A full suite of pre-built Grafana dashboards to view DSE server and OS metrics of a DSE cluster.

# Introduction 

Although the DataStax has already simplified the integration of DSE MC with Prometheus and Grafna, the [procedure](https://docs.datastax.com/en/monitoring/doc/monitoring/metricsCollector/mcExportMetricsDocker.html) involved still has many work involved. For example,

* We still need to install docker and docker compose on the host machine where we intend to run Prometheus and Grafana (assuming we don't have existing Prometheus and Grafana servers)
* We still need to configure "collectd" and DSE MC on each of DSE servers.
* We still need to adjust Prometheus configuration per DSE cluster so it can monitor all DSE nodes within the cluster.

This repository aims to fully automate the DSE MC integration procedure with (container based) Prometheus and Grafana servers. All the above mentioned manual steps are fully taken care of and it is also able to detect DSE cluster specific information (e.g. DSE cluster name; DSE node IP list) automatically.

## Usage

```bash
ansible-playbook -i ./hosts dse_metrics_collector.yaml --private-key <ssh_private_key> -u <ssh_user>
```
