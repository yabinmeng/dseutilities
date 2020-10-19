# Overview

[DataStax Astra (Astra)](https://astra.datastax.com) is a database-as-a-service offering from DataStax that is based on Apache Cassandra (C*) active-everywhere NoSQL database. It eliminates the overhead to install and operate C* and can be deployed on common cloud platoforms like AWS, GCP, and Azure by just clicking a few buttons.

DataStax Astra has a free tier plus a few other [paid service tiers options](https://docs.astra.datastax.com/docs/service-tier-options)

[DataBricks Community Edition (DCE)](https://community.cloud.databricks.com/) is the free version of [DataBrick's Unified Data Analytics Platform](https://databricks.com/product/unified-data-analytics-platform) that allows people to run various Apache Spark based tasks without the need to install and manage an Apache Spark cluster explicitly. 

**Objective** 

In this repo, I'm going to demonstrate how to use DCE to load data from an CSV file and save it into an Astra table; read data from an Astra table and process it in DCE.

## Source Sample Data Set

The source sample data set (in CSV format) is exported from GCP's public dataset regarding COVID-19 cases in Italy. For more details of the data set structure, you can 
* Vew it from GCP BigQuery(BQ), with BQ dataset name as <span style="color:lightblue">**bigquery-public-data.covid19_italy)**</span>, or 
* Check it from Kaggle website at: https://www.kaggle.com/bigquery/covid19-italy

To simplify the data loading process into DCE (which is not the focus of this repo), I exported the sample dataset from GCP BQ into a CSV file. 

# Environment Setup

## Astra Database

In order to create an Astra Database, we need:

* Register an account with DataStax Astra
* Sign in with the account and follow the procedure as described in [this document](https://docs.astra.datastax.com/docs/creating-your-astra-database).

### Get Astra Database Secure Connection Bundle (Driver based connection)

There are several ways to connect to an Astra DataBase, such as using Rest API, GraphQL API, or DataStax driver.

In this repo, we're going to connect to an Astra database from a DCE notebook using [DataStax Spark Cassandra Connector](https://github.com/datastax/spark-cassandra-connector) for read/write. This is a (java) driver based connection.

For driver based connection to an Astra database, we need to download the secure connection bundle, as described in [this procedure](https://docs.astra.datastax.com/docs/obtaining-database-credentials).


In this repo, an Astra database named **MyAstraDB** is created and the corresponding downloaded secure connection bundle file is:

* secure-connect-myastradb.zip

## Databricks Cluster

In order to create a Databricks cluster, we need:

* Register an account with Databricks: https://databricks.com/try-databricks
* Sign in DCE with the account and follow the procedure as described in [this document](https://docs.databricks.com/clusters/create.html)

In this repo, I created a cluster with the following Databricks runtime version:
* 7.3 LTS (includes Apache Spark 3.0.1, Scala 2.12)

## Spark Cassandra Connector (SCC)

### Version Requirement

In order to connect to an Astra database using SCC, we need at least version 2.5.1 which starts to support Astra.

Since the DCE cluster created ealier is based on Spark version 3.0.1, we need to use **version 3.0** which is compatible with Spark 3.x. Please check SCC compatibility [here](https://github.com/datastax/spark-cassandra-connector#version-compatibility)

### Standard vs Shaded Assembly Jar

In order to use SCC in a Databricks cluster properly, we <span style="color:lightblue">**MUST**</span> use **SCC shaded assembly jar** which includes all the required depencies with some conflicting libraries being shaded out. Otherwise, there might have some library conflicts between OSS Spark library and SCC library.

Download the SCC assembly jar from the following Maven Repository:
https://mvnrepository.com/artifact/com.datastax.spark/spark-cassandra-connector-assembly_2.12/3.0.0

### Install SCC as Databricks Cluster Library

We need to install SCC as a Databricks cluster library:

* Select the target Databricks clsuter
* On the "Libraries" tab, click "Install New"
* On the "Install Library" window, choose to upload library Jar file from local machine and click "Install"

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/cluster.library.png" width=800>

The uploaded library file will be stored in Databricks file system (DBFS), as below:
<image src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/cluster.library.installed.png" width= 800>

## Upload Data into Databricks Cluster

We also need to upload 2 files in Databricks cluster. One is the raw source sample data set (**covid19_italy_national_trends.csv**) and another is the Astra connection secure bundle file (**secure-connect-myastradb.zip**). Once uploaded, they will be stored in Databricks file system. The procedure of uploading these fiels are ase blow:

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/add.data.1.png" width=600>

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/add.data.2.png" width=600>





