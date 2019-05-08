# Overview

This document describes the procedure of how to use [Jupyter notebook](https://jupyter.org/) as a front-end data science analytical tool to examine data stored in DSE (core/C*) through DSE Analytics (Spark) and R. 

## Environment Setup

In order to clearly describe the proceure, we set up a testing environment which includes: 

* **One DSE (6.7.3) cluster with DSE Analytics (Spark) enabled** 

In this document, I'll skip the procedure of provisioning and configuring a DSE cluster. Please check official DSE document for more information. For simplicity purpose, the testing DSE cluster is a single-DC, 2-node cluster

* **One Jupyter client node/instance**

The focus of this document is on how to set up and prepare this client node/instance so end users can create a Jupyter notebook (from its web UI) and use it for advanced data science oriented analysis on the C* data that is stored in the DSE cluster, via Spark and R.

The client node/instance needs to be able to successfully connect to the DSE cluster via native CQL protocol (default port 9042). 

# Procedure Detail

## DSE SparkR Console

DSE Analytics (Spark) has the support for all Spark components, including SparkR. It is therefore has its own SparkR console where R code can be executed with the direct interaction with Spark though a SparkSession variable named as "spark". On every DSE Analytics node, you can launch this console via the following command without extra configuration/setup.
```
  $ dse sparkR
```

