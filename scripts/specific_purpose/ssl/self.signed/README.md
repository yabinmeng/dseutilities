# Background Overview

When DSE client-to-server and server-to-server encryption is enabled, the most important step is to create the keystore and truststore files for each DSE node. This step is not conceptually clear, but practically it is complex and lenghth. For example, DataStax documentation (https://docs.datastax.com/en/security/6.7/security/secSetUpSSLCert.html#secSetUpSSLCert) describes the procedure of how to create the keystore and truststore files based on self-signed root CA certificate. As we can see, the procedure involves quite a few steps and the procedure needs to be repeated for each DSE node.

# Script Description

## Objective

The purpose of this script is to automate the procedure as described in the above DataStax documentation for the creation of the keystore and truststore files as needed for every node in a DSE cluster. 

## Usage

The general script usage is as below:
```
Usage: genSelfSignSSL.sh [-h | <hostname_or_ip_list_file> <JKS|PKCS12>]
```
