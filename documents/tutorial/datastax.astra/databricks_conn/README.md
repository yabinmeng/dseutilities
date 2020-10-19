- [1. Overview](#1-overview)
  - [1.1. Source Sample Data Set](#11-source-sample-data-set)
- [2. Environment Setup](#2-environment-setup)
  - [2.1. Astra Database](#21-astra-database)
    - [2.1.1. Get Astra Database Secure Connection Bundle (Driver based connection)](#211-get-astra-database-secure-connection-bundle-driver-based-connection)
  - [2.2. Databricks Cluster](#22-databricks-cluster)
  - [2.3. Spark Cassandra Connector (SCC)](#23-spark-cassandra-connector-scc)
    - [2.3.1. Version Requirement](#231-version-requirement)
    - [2.3.2. Standard vs Shaded Assembly Jar](#232-standard-vs-shaded-assembly-jar)
    - [2.3.3. Install SCC as Databricks Cluster Library](#233-install-scc-as-databricks-cluster-library)
  - [2.4. Upload Data into Databricks Cluster](#24-upload-data-into-databricks-cluster)
  - [2.5. Update Databricks Cluster Spark Configuration](#25-update-databricks-cluster-spark-configuration)
- [3. Load Data using Databricks Spark and Save Data in Astra](#3-load-data-using-databricks-spark-and-save-data-in-astra)
  - [3.1. Read source CSV data into a Spark DataFrame](#31-read-source-csv-data-into-a-spark-dataframe)
  - [3.2. Using SCC, create an Astra keyspace and table (if not exists) based on the DataFrame schema; Save data in the Astra table](#32-using-scc-create-an-astra-keyspace-and-table-if-not-exists-based-on-the-dataframe-schema-save-data-in-the-astra-table)
  - [3.3. Verfiy Result in Astra Database](#33-verfiy-result-in-astra-database)

# 1. Overview

[DataStax Astra (Astra)](https://astra.datastax.com) is a database-as-a-service offering from DataStax that is based on Apache Cassandra (C*) active-everywhere NoSQL database. It eliminates the overhead to install and operate C* and can be deployed on common cloud platoforms like AWS, GCP, and Azure by just clicking a few buttons.

DataStax Astra has a free tier plus a few other [paid service tiers options](https://docs.astra.datastax.com/docs/service-tier-options)

[DataBricks Community Edition (DCE)](https://community.cloud.databricks.com/) is the free version of [DataBrick's Unified Data Analytics Platform](https://databricks.com/product/unified-data-analytics-platform) that allows people to run various Apache Spark based tasks without the need to install and manage an Apache Spark cluster explicitly.

**Objective**

In this repo, I'm going to demonstrate how to use DCE to load data from an CSV file and save it into an Astra table; read data from an Astra table and process it in DCE.

## 1.1. Source Sample Data Set

The source sample data set (in CSV format) is exported from GCP's public dataset regarding COVID-19 cases in Italy. For more details of the data set structure, you can

* Vew it from GCP BigQuery(BQ), with BQ dataset name as <span style="color:lightblue">**bigquery-public-data.covid19_italy)**</span>, or
* Check it from Kaggle website at: <https://www.kaggle.com/bigquery/covid19-italy>

To simplify the data loading process into DCE (which is not the focus of this repo), I exported the sample dataset from GCP BQ into a CSV file.

# 2. Environment Setup

## 2.1. Astra Database

In order to create an Astra Database, we need:

* Register an account with DataStax Astra
* Sign in with the account and follow the procedure as described in [this document](https://docs.astra.datastax.com/docs/creating-your-astra-database).

### 2.1.1. Get Astra Database Secure Connection Bundle (Driver based connection)

There are several ways to connect to an Astra DataBase, such as using Rest API, GraphQL API, or DataStax driver.

In this repo, we're going to connect to an Astra database from a DCE notebook using [DataStax Spark Cassandra Connector](https://github.com/datastax/spark-cassandra-connector) for read/write. This is a (java) driver based connection.

For driver based connection to an Astra database, we need to download the secure connection bundle, as described in [this procedure](https://docs.astra.datastax.com/docs/obtaining-database-credentials).

In this repo, an Astra database named **MyAstraDB** is created and the corresponding downloaded secure connection bundle file is:

* secure-connect-myastradb.zip

## 2.2. Databricks Cluster

In order to create a Databricks cluster, we need:

* Register an account with Databricks: <https://databricks.com/try-databricks>
* Sign in DCE with the account and follow the procedure as described in [this document](https://docs.databricks.com/clusters/create.html)

In this repo, I created a cluster with the following Databricks runtime version:

* 7.3 LTS (includes Apache Spark 3.0.1, Scala 2.12)

## 2.3. Spark Cassandra Connector (SCC)

### 2.3.1. Version Requirement

In order to connect to an Astra database using SCC, we need at least version 2.5.1 which starts to support Astra.

Since the DCE cluster created ealier is based on Spark version 3.0.1, we need to use **version 3.0** which is compatible with Spark 3.x. Please check SCC compatibility [here](https://github.com/datastax/spark-cassandra-connector#version-compatibility)

### 2.3.2. Standard vs Shaded Assembly Jar

In order to use SCC in a Databricks cluster properly, we <span style="color:lightblue">**MUST**</span> use **SCC shaded assembly jar** which includes all the required depencies with some conflicting libraries being shaded out. Otherwise, there might have some library conflicts between OSS Spark library and SCC library.

Download the SCC assembly jar from the following Maven Repository:
<https://mvnrepository.com/artifact/com.datastax.spark/spark-cassandra-connector-assembly_2.12/3.0.0>

### 2.3.3. Install SCC as Databricks Cluster Library

We need to install SCC as a Databricks cluster library:

* Select the target Databricks clsuter
* On the "Libraries" tab, click "Install New"
* On the "Install Library" window, choose to upload library Jar file from local machine and click "Install"

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/cluster.library.png" width=800>

The uploaded library file will be stored in Databricks file system (DBFS), as below:

<image src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/cluster.library.installed.png" width= 800>

## 2.4. Upload Data into Databricks Cluster

We also need to upload 2 files in Databricks cluster. One is the raw source sample data set (**covid19_italy_national_trends.csv**) and another is the Astra connection secure bundle file (**secure-connect-myastradb.zip**). Once uploaded, they will be stored in Databricks file system. The procedure of uploading these fiels are ase blow:

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/add.data.1.png" width=600>

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/add.data.2.png" width=600>

## 2.5. Update Databricks Cluster Spark Configuration

As the last step of environment setup, we need to add several Spark configuration items that are needed by SCC (see [SCC reference doc](spark.cassandra.connection.config.cloud.path)):

*  spark.cassandra.connection.config.cloud.path: Astra database secure connection bundle
*  spark.cassandra.auth.username: Astra database connection username
*  spark.cassandra.auth.password: Astra database connection password

In order to do so, select the Databricks cluster and edit it. In the cluster editing page, enter the above configuration items in "Spark Config" field under "Spark" tab, as below:

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/spark_config.png" width=600>

Then click "Confirm and Restart" button at the top to restart the Spark cluster.

# 3. Load Data using Databricks Spark and Save Data in Astra

At this point, we're ready to run some code that runs on the Databricks Spark cluster to load the source sample data in CSV format and save it into the Astra database. Let's create a notebook for this:

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/create_notebook.png" width=600>

In my testing, the code is Scala based has 2 main parts:

## 3.1. Read source CSV data into a Spark DataFrame

```
// Read source sample data
val covid_trends = spark.read.format("csv")
  .option("header", "true")
  .option("inferSchema", "true")
  .load("dbfs:/FileStore/tables/covid19_italy_national_trends.csv")

covid_trends.printSchema()
//covid_trends.show(1)
```

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/notebook_cell1.png" width=800>

## 3.2. Using SCC, create an Astra keyspace and table (if not exists) based on the DataFrame schema; Save data in the Astra table
  
```
import com.datastax.spark.connector._
import org.apache.spark.sql.cassandra._

// Create a keyspace and table in Astra
// ------------------------------------
val tgtKsName = "testks"
val tgtTblName = "covid_trends"

// Check if the target Astra keyspace and table already exists
val sysSchemaTableDF = spark.read
  .cassandraFormat("tables", "system_schema")
  .load()
  .filter("table_name == '" + tgtTblName + "'")
  .filter("keyspace_name == '" + tgtKsName + "'")
val exists = sysSchemaTableDF.count()
//println("Target table exists = " + exists)

if ( exists == 0 ) {
  // Create an Astra table using DataFrame functions
  covid_trends.createCassandraTable(
    tgtKsName,
    tgtTblName,
    partitionKeyColumns = Some(Seq("country", "date")))
}

// Save data in the Astra table that was jsut created
covid_trends.write
        .cassandraFormat(tgtTblName, tgtKsName)
        .mode("append")
        .save()
```

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/notebook_cell2.png" width=800>

## 3.3. Verfiy Result in Astra Database

Now let's log into Astra and verify the result. From the screenshot below, we can see that the Astra table is succesfully created and data is loaded correctly.

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/databricks_conn/resources/screenshots/astra_result.png" width=800>
