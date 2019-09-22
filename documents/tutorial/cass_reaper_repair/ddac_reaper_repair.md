# Overview 

## Background Introduction

DataStax has announced DDAC (DataStax Distribution of Apache Cassandra) in late 2018 as a "a new subscription offering designed for running a certified version of open source Apache Cassandra (C*) for development and production use cases that do not have the higher enterprise demands better served by [DataStax Enterprise](https://www.datastax.com/products/datastax-enterprise).

Since DDAC is designed as a "supported **OSS** C*", it doesn't have the enterprise features as offered in DSE. It also can't utilize other enterprise-oriented DSE tools like [DataStax OpsCenter](https://www.datastax.com/products/datastax-opscenter). This means that when using DDAC, we can't utilize all features as provided by OpsCenter for cluster operation management, metrics monitoring and dashboarding, advanced services like for backup or repair, and and so on. 

Because of this, for DDAC users, they need to fall back to the basic, command-line based features as provided out of the box of OSS C*. For example, if they want to run a repair against the cluster, they have to run "nodetool repair" command somehow on each of the node in the cluster. This is a manual process and usually it can take a long time to finish repairing the entire cluster when the data size is not small.

## Full Repair, Primary-Range Repair, and Sub-Range Repair

**Full Repair** 

When running "nodetool repair" command, by default it is running a full repair, which means on the node where the command runs, it will repair both primary-range data and secondary-range data. Primary-range data means the data is owned by this node by the calculation of the partitioning hash function. Secondary-range data means the replica data that is replicated from other nodes.

When executing the full repair on each node of the cluster (an entire repair cycle), it means that the same data has been repaired RF times (RF means the replication factor). This makes full repair resource heavy and time consuming.

**Primary-Range Repair**

In order to reduce the impact of a full repair, we can run the repair via "nodetool repair -pr" command. The "-pr" option means when doing repair on a node, it is only going to focus on primary-range data, but not on secondary-range data. Because of this, when we execute an entire repair cycle (on each node of the cluster), there is no "duplicate" repair of data; and is therefore faster and less resource consuming as compared to the full repair. 

One thing that needs to pay attention to here is when taking this approach, primary-range repair command has to be executed on every node of the cluster in order to make sure the entire data set is repaired. 

For full repair, technically speaking, as long as the command is executed on (N - RF + 1) nodes (N is the number of nodes in the cluster and RF is the replciation factor), the entire data set is repaired. 

**Sub-Range Repair**

Sub-range repair is achieved by executing "nodetool repair -st <starting_token> -et <ending_token>". Using sub-range repair can further limit the scope of each repair session by providing a smaller range of tokens as compared to the whole (primary) range of data. Concurrent repair on different sub-ranges of data is also possible. Because of this, sub-range repair can be less resource consuming and more flexible. But meanwhile, in order to complete the repair on the entire data set, a schedule needs to be established to divide the data into a complete list of sub-ranges and make sure each sub-range is repaired. 

---

DataStax OpsCenter repair service is based on sub-range repair and handles the sub-range management and scheduling automatically.


# Introduction to Cassandra Reaper (Reaper)

[Cassandra Reaper](http://cassandra-reaper.io/) { GitHub Code [here](https://github.com/thelastpickle/cassandra-reaper) } is an open source effort that tries to simplify and automate C* repair, providing a functionality that is similar to what DataStax OpsCenter repair service offers. It was originally developed by [Spotify](https://www.spotify.com/us/) and is now taken over by [The Last Pickle](https://thelastpickle.com/) for active development and/or maintainence.

Please note that compared with Cassandra Reaper, DataStax OpsCenter is a far more advanced product for many tasks of different purposes such as metrics monitoring, dashboarding, alerting, cluster management and operation like node start/stop, token balance, backup/restore, repair, performance tuning, and so on. 

The sole purpose of Cassandra Reaper is for C* data repair mangement and automation. Like DataStax OpsCenter repair service, it is also based on sub-range repair. 

## Installation

This section describes the method of how to install Reaper (as a service) on Debian based Linux systems like Ubuntu). For other installation methods, please refer to Reaper's official document.

```
echo "deb https://dl.bintray.com/thelastpickle/reaper-deb wheezy main" | sudo tee -a /etc/apt/sources.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2895100917357435
sudo apt-get update
sudo apt-get install reaper
```

The APT package installation creates a service named **cassandra-reaper** and an OS service user, **reaper**. We can start, stop, or check status of this service using the following commands:

```
sudo service cassandra-reaper [start|stop|status]
```

Reaper server program is java based and by default it is allocated with 2GB heap size. If it is needed to increase the heap size, we can modify the following JVM options (in particular -Xms and -Xmx options) in file ***/usr/local/bin/cassandra-reaper***.
```
JVM_OPTS=(
    -ea
    -Xms2G
    -Xmx2G
    # Prefer binding to IPv4 network intefaces (when net.ipv6.bindv6only=1). See
    # http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=6342561 (short version:
    # comment out this entry to enable IPv6 support).
    -Djava.net.preferIPv4Stack=true
    )
```

## Access

### Web UI

Once the service is started, we can access Reaper web UI from the following url:
```
http://<IP_address>:8080/webui/
```

By default Reaper has authentication enabled. So when we access the above web UI first time, the landing page of the  web UI is the login page. A default username/password combination, ***admin/admin*** or ***user/user*** can be used for login purpose.

Please NOTE that Reaper authentication is based on [Apache Shiro](https://shiro.apache.org/). So more advanced security features like LDAP integration, password encryption, and etc. are also possible with Reaper. For production deployment and/or for more advanced security features, we should customize **shiro.ini** file (and put it under folder /etc/cassandra-reaper). A template file can be found from Reaper Github repo [here](https://github.com/thelastpickle/cassandra-reaper/blob/master/src/server/src/main/resources/shiro.ini). The detailed discussion of these features, however, is beyond the scope of this document. Please refer to [Shiro's documentation](https://shiro.apache.org/documentation.html) for more info.

### CLI and Rest API

All functionalities as exposed by Reaper Web UI can also be accessed via a CLI tool, **spreaper** (e.g. /usr/local/bin/spreaper), as provided out of the box of Reaper installaiton.

**spreaper** utility is a python wrapper program around Reaper's Rest APIs. The detailed description of the APIs can be found [here](http://cassandra-reaper.io/docs/api/).

## Backend Storage

The main configuration file for Reaper is file **cassandra-reaper.yaml** (*/etc/cassandra-reaper/cassandra-reaper.yaml*). There are several templates of this file that are provided out of the box (that can be found under folder ***/etc/cassandra-reaper/configs/***). The templates are based on Reaper's backend storage type. 

Reaper can use the following storage types as its backend mechanism:
* In-memory (default)
* H2
* Postgres
* Cassandra

In this document, we'll focus on how to use Cassandra as the backend storage. 


# DDAC(C*) Cluster Configuration

For simplicity purpose, in my test, I'm using the same DDAC (C*) cluster that Reaper is going to manage for repair as Reaper's own backend C* storage cluster. Practically speaking, it is recommended to use a separate DDAC (C*) cluster.

The DDAC(C*) cluster used in my test has the following security features enabled:
* JMX authentication 
* JMX SSL
* C* (internal) authentication
* C* client-to-server and server-to-server SSL encryption

These security features are purposely chosen in order to test the connection between Reaper and DDAC(C*), both as a storage backend storage cluster and a managed cluster.

### Cassandra Authentication, Client-to-Server SSL, and Server-to-Sever SSL

The following security features in **cassandra.yaml** file have been enabled for the DDAC (C*) cluster:

```
# Authentication
authenticator: PasswordAuthenticator

# Client-to-Server SSL
client_encryption_options:
    enabled: true
    optional: false
    keystore: <keystore_file_path>
    keystore_password: <keystore_password>

# Server-to-Server SSL
server_encryption_options:
    internode_encryption: all
    keystore: <keystore_file_path>
    keystore_password: <keystore_password>
    truststore: <turststore_file_path>
    truststore_password: <truststore_password>
    require_client_auth: true
```

When Reaper chooses to use this DDAC(C*) cluster as its backend storage, its connection to the cluster is enforced by the above security settings (esp. Authentication and Client-to-Server SSL)


### JMX Authentication and SSL Configuration (as a monitored cluster)

Reaper uses JMX to manage DDAC(C*) clusters for repair. Because of this, each DDAC(C*) cluster needs to have remote JMX enabled, which in turn has JMX authentication enabled by default. It is also recommended to have JMX SSL enabled in order to encrypt in-flight JMX communiction.

The JMX security settings are enabled in **cassandra-envs.sh** file, as below:

```
LOCAL_JMX=no

if [ "x$LOCAL_JMX" = "x" ]; then
    LOCAL_JMX=yes
fi

# Specifies the default port over which Cassandra will be available for
# JMX connections.
# For security reasons, you should not expose this port to the internet.  Firewall it if needed.
JMX_PORT="7199"

if [ "$LOCAL_JMX" = "yes" ]; then
  JVM_OPTS="$JVM_OPTS -Dcassandra.jmx.local.port=$JMX_PORT"
  JVM_OPTS="$JVM_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
else
  JVM_OPTS="$JVM_OPTS -Dcassandra.jmx.remote.port=$JMX_PORT"
  # if ssl is enabled the same port cannot be used for both jmx and rmi so either
  # pick another value for this property or comment out to use a random port (though see CASSANDRA-7087 for origins)
  JVM_OPTS="$JVM_OPTS -Dcom.sun.management.jmxremote.rmi.port=$JMX_PORT"

  # turn on JMX authentication. See below for further options
  JVM_OPTS="$JVM_OPTS -Dcom.sun.management.jmxremote.authenticate=true"

  # jmx ssl options
  JVM_OPTS="$JVM_OPTS -Dcom.sun.management.jmxremote.ssl=true"
  #JVM_OPTS="$JVM_OPTS -Dcom.sun.management.jmxremote.ssl.need.client.auth=true"
  #JVM_OPTS="$JVM_OPTS -Dcom.sun.management.jmxremote.ssl.enabled.protocols=<enabled-protocols>"
  #JVM_OPTS="$JVM_OPTS -Dcom.sun.management.jmxremote.ssl.enabled.cipher.suites=<enabled-cipher-suites>"
  JVM_OPTS="$JVM_OPTS -Djavax.net.ssl.keyStore=/opt/ddac-5.1.16/security/dseKeystore_172-31-66-133.jks"
  JVM_OPTS="$JVM_OPTS -Djavax.net.ssl.keyStorePassword=MyKeyStorePass"
  JVM_OPTS="$JVM_OPTS -Djavax.net.ssl.trustStore=/opt/ddac-5.1.16/security/dseTruststore.jks"
  JVM_OPTS="$JVM_OPTS -Djavax.net.ssl.trustStorePassword=MyTrustStorePass"
fi

JVM_OPTS="$JVM_OPTS -Dcassandra.jmx.remote.login.config=CassandraLogin"
JVM_OPTS="$JVM_OPTS -Djava.security.auth.login.config=$CASSANDRA_HOME/conf/cassandra-jaas.config" 
```

