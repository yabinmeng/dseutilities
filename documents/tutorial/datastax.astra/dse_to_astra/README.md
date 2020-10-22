# Overview

In my previous [tutorial](https://github.com/yabinmeng/dseutilities/tree/master/documents/tutorial/datastax.astra/databricks_conn), I demonstrated how to use Databricks Spark platform (e.g. Azure Databricks service) to load data from an external source (a CSV file) into a DataStax Astra database. 

In this tutorial, I will demonstrate how to use Databricks Spark to load data from a stand-alone Cassandra (C*) cluster into a DataStax Atra database.

# Environment Setup

For testing purpose in this repo., we need a stand-alone C* cluster and a Databricks cluster and most importantly we need to make sure these two cluster can communicate with each other. In order to achieve this task, I'm taking the following approach:

* Lauch a Databricks service on Azure using Azure Databricks service
* Launch several Azure virtual machines and install a DSE clsuter on it
* Make sure the launched Azure Databricks service and and the DSE virtual machines **belong to the same Azure virtual network**.

## Set up Azure Resources

The detailed procedure of setting up Azure resources is beyond the scope of this tutorial. Please refer to Azure documenatation for it. In this repo., I will only list the Azure resources and relevant key characteristics that are needed by our testing in this repo. 

In the testing, all Azure resources are created in the same Azure region: **Central US**

1. Create an Azure resource group (RG), E.g. MyAstraDtbrksRG

2. Create an Azure virtual network (VN). When creating the VN, make sure to explicitly specify the following key properties:
   
   * Resource group: the RG that was created earlier (e.g. MyAstraDtbrksRG)
   * Name and CIDR range for VN address space, e.g. 
     * Name: MyAstraDtbrksVN
     * CIDR: 10.4.0.0/16
   * Name and CIDR range for one Subnet(SN), e.g.
     * Name: MyAstraDtbrksVN-Workload-SN
     * CIDR: 10.4.10.0/24

3. Create serveral Azure virtual machines (VM). When creating the VMs, make sure to explicitly specify the following key properties:

   * Resource group: the RG that was created earlier (e.g. MyAstraDtbrksRG)
   * Size: Azure instance type (e.g. Standard_D4s_v3, 16 Gib memory)
   * Virtual Network: the VN that was created earlier (e.g. MyAstraDtbrksVN)
   * Subnet: the SN that was created earlier (e.g. MyAstraDtbrksVN-Workload-SN)
  
Also create and share a common SSH key pair among all the created VMs. All other properperties can be left as default

4. Create an Azure Databricks Workspace (ADW), make sure to explicitly specify the following key properties:

   * Resource group: the RG that was created earlier (e.g. MyAstraDtbrksRG)
   * Pricing Tier: (e.g. Standard)
   * Deploy Azure Databricks workspace in your own Virtual Network (VNet): Yes
     * Virtual Network: the VN that was created earlier (e.g. MyAstraDtbrksVN)
     * Public Subnet Name and CIDR. Make sure the CIDR range is alinged with the VN CIDR range that was specified earlier and not overlapping with the existing subnet for VMs, e.g.
       * Name: MyAzureDbrksPubSN
       * CIDR: 10.4.255.0/24
    * Public Subnet Name and CIDR. Make sure the CIDR range is alinged with the VN CIDR range that was specified earlier, e.g.
       * Name: MyAzureDbrksPrvSN
       * CIDR: 10.4.20.0/24 

## Set up and Prepare DSE/C* Cluster

On each of the launched VMs, do the following tasks:

* Install OpenJDK 8 
* Install latest DSE 6.8 release (6.8.5) binary ([procedure](https://docs.datastax.com/en/install/6.8/install/installDEBdse.html))
* Make neccsary changes in cassandra.yaml to form one DSE/C* cluster
* Create a C* keyspace (**testks**) and a table (**testbl_azure**) for testing purpose and insert some data in the table

```
cqlsh> desc table testks.testbl_azure ;

CREATE TABLE testks.testbl_azure (
    cola int PRIMARY KEY,
    colb text
)
... ...

cqlsh> select * from testks.testbl_azure ;

 cola | colb
------+-------------
  100 | azure-row-100
  200 | azure-row-200
  300 | azure-row-300

(3 rows)
```

## Set up and Prepare an Astra Database

In this repo, I will use the same Astra database as in my [previous repo.](https://github.com/yabinmeng/dseutilities/tree/master/documents/tutorial/datastax.astra/databricks_conn).

Create a table (**testks.testbl_astra**) that has similar table structure as the one created above in the DSE clsuter.

```
cqlsh> desc table testks.testbl_azure ;

CREATE TABLE testks.testbl_astra (
    cola int PRIMARY KEY,
    colb text
)
... ...

cqlsh> select * from testks.testbl_astra ;

 cola | colb
------+-------------
    0 | astra-row-0
    1 | astra-row-1
    2 | astra-row-2

(3 rows)
```


## Set up and Prepare Databricks Spark Cluster

In the Azure Databricks workspace, create a Spark cluster with the following properties:

* Cluster Name: the name of the created cluster, e.g. MyDbrksSparkCluster
* Cluster Mode: standard
* Databricks Runtimes: 7.3 LTS (Scala 2.12, Spark 3.0.1)

Once the Spark cluster is created, 

* Install Spark Cassandra Connector (SCC) version 3.0 library (see [procedure](https://github.com/yabinmeng/dseutilities/tree/master/documents/tutorial/datastax.astra/databricks_conn#233-install-scc-as-databricks-cluster-library))

* Upload DataStax Astra secure connect bundle file (see [procedure](https://github.com/yabinmeng/dseutilities/tree/master/documents/tutorial/datastax.astra/databricks_conn#24-upload-data-into-databricks-cluster))

* Add the following cluster level Spark configuration (see [procedure](https://github.com/yabinmeng/dseutilities/tree/master/documents/tutorial/datastax.astra/databricks_conn#25-update-databricks-cluster-spark-configuration))

```
spark.files dbfs:/FileStore/tables/<secure_connect_bundle>.zip
spark.dse.continuousPagingEnabled false
```

**NOTE** that compared with my previous tutorial, I do NOT set the following Astra connection related Spark configuration items at **cluster** level. Instead, they're set at **catalog** level dynamically in the code. I will cover this with more details in the later sections.

```
spark.cassandra.connection.config.cloud.path <secure_connect_bundle>.zip
spark.cassandra.auth.username <astra_username>
spark.cassandra.auth.password <astra_passwd>
```

# Migrate Data between tow C* based Clusters using SCC

For most time, people use SCC for data migration/ETL related work between a C* cluster and another non-C* system (e.g. an RDBMS, another NoSQL database, etc.). But SCC can also connect to multiple C* clusters and therefore makes possible data migration between 2 C* based clusters. In our testing in this repo, I will use Databricks cluster + SCC to migrate data from a DSE cluster to a Astra database.

## Cassandra Catalog (Spark 3.0 + SCC 3.0)

Spark 3.0 adds support for Catalog Plugin API [SPARK-31121](https://issues.apache.org/jira/browse/SPARK-31121) which is an umbrella ticket that includes many improvements related Apache Spark DataSource V2 API.

Based on the improved functionalities/features of Spark DataSource V2 API, SCC 3.0 introduces the concept of Cassandra Catalog. Cassandra Catalog brings many advantages and greatly simplifies many tasks regarding Spark Cassandra connection. For example, using Cassandra Catalog, we can connect to multiple Cassandra clusters in one Spark session, as demonstrated below:

<img src="https://github.com/yabinmeng/dseutilities/blob/master/documents/tutorial/datastax.astra/dse_to_astra/resources/screenshots/cassandra.catalog.png" width=400>

For more detailed introduction of **Cassandra Catalog**, please refer to Russell Spitzer's 2020 Spark Summit [presentation](https://databricks.com/session_na20/datasource-v2-and-cassandra-a-whole-new-world) (the above screenshot is also taken from his presentation).

With Cassandra Catalog, the code to migrate from the DSE cluster to the Astra database is straightforward

```
import com.datastax.spark.connector._
import com.datastax.spark.connector.cql._

//--------------------------
// Catalog to the source DSE cluster
val dseClusterAlias = "DseCluster"
val dseCatName = "spark.sql.catalog." + dseClusterAlias
val dseSrvIp = "<dse_srv_ip>"
val dseSrvPort = "9042"

spark.conf.set(dseCatName, "com.datastax.spark.connector.datasource.CassandraCatalog")
spark.conf.set(dseCatName + ".spark.cassandra.connection.host", dseSrvIp)
spark.conf.set(dseCatName + ".spark.cassandra.connection.port", dseSrvPort)

// -- read from DSE 
val tblDf_d = spark.read.table(dseClusterAlias + ".testks.testbl_azure")
println(">> [Step 1] Read from DSE: testks.testbl_azure")
tblDf_d.show()

//--------------------------
// Catalog  to the target Astra cluster
val astraClusterAlias = "AstraCluster"
val astraCatName = "spark.sql.catalog." + astraClusterAlias
val astraSecureConnFilePath = "dbfs:/FileStore/tables/secure_connect_myastradb.zip"
val astraSecureConnFileName = astraSecureConnFilePath.split("/").last
val astraUserName = "<astra_username>"
val astraPassword = "<astra_password>"

spark.conf.set(astraCatName, "com.datastax.spark.connector.datasource.CassandraCatalog")
//spark.conf.set(astraCatName + ".spark.files", astraSecureConnFilePath)
spark.conf.set(astraCatName + ".spark.cassandra.connection.config.cloud.path", astraSecureConnFileName)
spark.conf.set(astraCatName + ".spark.cassandra.auth.username", astraUserName)
spark.conf.set(astraCatName + ".spark.cassandra.auth.password", astraPassword)

// -- read from Astra 
val tblDf_a = spark.read.table(astraClusterAlias + ".testks.testbl_astra")
println(">> [Step 2] Read from Astra: testks.testbl_astra")
tblDf_a.show()

//--------------------------
// -- Write to Astra
println(">> [Step 3] Write DSE data into Astra: testks.testbl_astra")
println
tblDf_d.writeTo(astraClusterAlias + ".testks.testbl_astra").append

//--------------------------
// -- Read from Astra again
println(">> [Step 4] Read again from Astra: testks.testbl_astra")
tblDf_a.show()
```

The result output is as below:

```
>> [Step 1] Read from DSE: testks.testbl_azure
+----+-------------+
|cola|         colb|
+----+-------------+
| 200|azure-row-200|
| 100|azure-row-100|
| 300|azure-row-300|
+----+-------------+

>> [Step 2] Read from Astra: testks.testbl_astra
+----+-----------+
|cola|       colb|
+----+-----------+
|   1|astra-row-1|
|   0|astra-row-0|
|   2|astra-row-2|
+----+-----------+

>> [Step 3] Write DSE data into Astra: testks.testbl_astra

>> [Step 4] Read again from Astra: testks.testbl_astra
+----+-------------+
|cola|         colb|
+----+-------------+
|   1|  astra-row-1|
|   0|  astra-row-0|
|   2|  astra-row-2|
| 200|azure-row-200|
| 100|azure-row-100|
| 300|azure-row-300|
+----+-------------+
```

Looking at the program output, we can clearly see that the data is succesfully migrated from the DSE cluster and landed in Astra.

One thing that is worthy to mention is about "Step 4" where we actually do NOT issue another "spark.read" command in order to read data from Astra for the second time. The new **Cassandra Catalog** feature in SCC 3.0 is able to automatically detect C* side changes in Spark.