# Background

When DSE client-to-server and server-to-server encryption (aka, in-transit SSL/TLS encryption) is enabled, the most important step is to create the keystore and truststore files for each DSE node. This step is not conceptually clear, but practically it is complex and lenghth. For example, DataStax documentation (https://docs.datastax.com/en/security/6.7/security/secSetUpSSLCert.html#secSetUpSSLCert) describes the procedure of how to create the keystore and truststore files based on self-signed root CA certificate. As we can see, the procedure involves quite a few steps and the procedure needs to be repeated for each DSE node.

# Script Description

## Objective

The purpose of this script is to automate the procedure as described in the above DataStax documentation for the creation of the keystore and truststore files as needed for every node in a DSE cluster. 

## Usage

The general script usage is as below:
```
Usage: genSelfSignSSL.sh [-h | <hostname_or_ip_list_file> <JKS|PKCS12>]
```

There are 2 mandatory parameters for this script:
1. The first is a text file name and the content of the file is a simple list of the hostname or IP address for all DSE nodes we want to create the keystore and truststore for in-transit SSL/TLS encryption. An example is as below (for a 3-node DSE cluster):
```
192.168.0.1
192.168.0.2
192.168.0.3
```
2. The second parameter specifies the certificate format to be used. The only options are JKS and PKCS12 which are both file-based certificate format types.


