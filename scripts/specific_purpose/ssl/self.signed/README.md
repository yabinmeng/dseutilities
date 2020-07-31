# Background

When DSE client-to-server and server-to-server encryption (aka, in-transit SSL/TLS encryption) is enabled, the most important step is to create the keystore and truststore files for each DSE node. This step is conceptually clear, but practically it is complex and lenghthy. For example, DataStax documentation (https://docs.datastax.com/en/security/6.7/security/secSetUpSSLCert.html#secSetUpSSLCert) describes the procedure of how to create the keystore and truststore files based on self-signed root CA certificate. As we can see, the procedure involves quite a few steps and the procedure needs to be repeated for each DSE node.

# Script Description

## Objective

The purpose of this script is to automate the procedure as described in the above DataStax documentation for the creation of the keystore and truststore files as needed for every node in a DSE cluster. 

## Usage Description

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

## Output

For the above 3-node DSE cluster, the DSE node list file is simply called **nodelist**. The command to generate PKCS12 based keystore and trustore files is as below. Please note that the execution of the command is generating a lot of command line messages describing each step involved.
```
$./genSelfSignedSSL.sh nodelist PKCS12
```

With the execution of this command, a folder called **SelfSignedSSL** is created under the current folder where the command is executed. Under this folder, there are subfolders that match the specified certificate format type ("pkcs12" in this example). Below this folder, the folder structure is as this:
* **.../cqlsh/**: the generated CQLSH client certificate (.csr) and private key (.key) for each DSE node

* **...keystore/**: the keystore file of the specified certificate format type (e.g. pkcs12) for each DSE node
  * **.../keystore/csr/**: the CSR (.csr) and signed certificate (.crt.signed) for each DSE node.

* **rootca**: the self-signed root ca certificate (.crt) and private key (.key)

* **truststore**: the one (and only one) trsustore file of the specified certificate format type (e.g. pkcs12) that is shared by all DSE nodes.

```
$ tree SelfSignedSSL/
SelfSignedSSL/
└── pkcs12
    ├── cqlsh
    │   ├── cqlsh_192-168-0-1.crt.signed
    │   ├── cqlsh_192-168-0-1.csr
    │   ├── cqlsh_192-168-0-1.key
    │   ├── cqlsh_192-168-0-2.crt.signed
    │   ├── cqlsh_192-168-0-2.csr
    │   ├── cqlsh_192-168-0-2.key
    │   ├── cqlsh_192-168-0-3.crt.signed
    │   ├── cqlsh_192-168-0-3.csr
    │   └── cqlsh_192-168-0-3.key
    ├── keystore
    │   ├── csr
    │   │   ├── dseKeystore-192-168-0-1.crt.signed
    │   │   ├── dseKeystore-192-168-0-2.crt.signed
    │   │   ├── dseKeystore-192-168-0-3.crt.signed
    │   │   ├── dseKeystore_192-168-0-1.csr
    │   │   ├── dseKeystore_192-168-0-2.csr
    │   │   └── dseKeystore_192-168-0-3.csr
    │   ├── dseKeystore_192-168-0-1.pkcs12
    │   ├── dseKeystore_192-168-0-2.pkcs12
    │   └── dseKeystore_192-168-0-3.pkcs12
    ├── rootca
    │   ├── rootca.crt
    │   └── rootca.key
    └── truststore
        └── dseTruststore.pkcs12
```

Please **NOTE** that you can execute this script on any computer. Once the files are generated, you can copy the files to all the nodes in cluster:
* Copy the common truststore file to each DSE node
* Copy each keystore file to the corresponding DSE node
* Copy each pair of CQLSH certificate and key files to the corresponding DSE node. 

Please also **NOTE** that the generated keystore and truststore passwords are "MyKeyStorePass" and "MyTrustStorePass" respectively. These are hard-coded in the script. Please change them accordingly for your own use case.

## About the Certificate Format JKS and PKCS12

* For DSE version before 6.7.7, JKS is the ONLY format that works for DSE in-transit SSL/TLS encryption. 
* For DSE verion 6.7.7 and above, both formats are working but PKCS12 is recommended.
