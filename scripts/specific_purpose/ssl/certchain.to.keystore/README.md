# Overview

In some cases, when we use a centralized, enterprise-level certificate management tool/utility, the tool/utility is able to generate a single combined (private) key and certificate chain file for a particular server node. Most likely, such a single combined file has the following component:

* Private key for the requested node
* Singed certificate for the requested node
* The (public) intermeidate CA certificate that signs the node-specific certificate
* The (public) root CA certificate that signs the intermediate CA certificate

Also for readability purpose, such a file also contains relevant bag attributes for each of the above components. An example of such a file (with key information removed) is provided in the section below.

Unfortunately this file format can't be utilized by DSE server directly which right now can only deal with Java keystore files ("keystore" and "truststore"). This utility gives a demo of how to handle such a file and generate the keystore and truststore files that are readable by a DSE server.

## Example Raw Cert Chain PEM File Structure

```bash
Bag Attributes
    Microsoft Local Key set: <No Values>
    localKeyID: xxx
    Microsoft CSP Name: Microsoft RSA SChannel Cryptographic Provider
    friendlyName: xxx
Key Attributes
    X509v3 Key Usage: 10
-----BEGIN PRIVATE KEY-----
... ...
-----END PRIVATE KEY-----
Bag Attributes
    localKeyID: xxx
subject=/C=US/ST=CA/L=SFC/O=ABC Corp/OU=IT/CN=testnode1.dc1.abccorp.com
issuer=/DC=com/DC=abccorp/DC=dc1/CN=DC1IntermediateCA01
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
Bag Attributes
    1.3.6.1.4.1.311.17.3.20: CE 89 0A CF 26 C8 6D 48 38 54 31 DB 7D 2B 7A 14 81 E5 EC 74
subject=/DC=com/DC=abccorp/DC=dc1/CN=DC1RootCA01
issuer=/DC=com/DC=abccorp/DC=dc1/CN=DC1RootCA01
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
Bag Attributes
    1.3.6.1.4.1.311.17.3.20: B5 BE 56 37 01 9B 64 88 6B 24 5A 2F 9D 3E 3F 7C B4 83 FA 93
subject=/DC=com/DC=abccorp/DC=dc1/CN=DC1IntermediateCA01
issuer=/DC=com/DC=abccorp/DC=dc1/CN=DC1RootCA01
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
Bag Attributes
    1.3.6.1.4.1.311.17.3.20: B5 BE 56 37 01 9B 64 88 6B 24 5A 2F 9D 3E 3F 7C B4 83 FA 93
subject=/DC=com/DC=abccorp/DC=dc1/CN=DC1IntermediateCA01
issuer=/DC=com/DC=abccorp/DC=dc1/CN=DC1RootCA01
-----BEGIN CERTIFICATE-----
```

## Usage

```bash
./splitCertChainRawFile <raw_crt_chain_file> <node_name>

e.g. ./splitCertChainRawFile exampleRawCrtChain.pem testnode1
```

### Output

Executing the above example is going to create a subfolder named "zzOutput" under the script execution folder. The target keystore and truststore files are generated under a subfolder on level down at "zzOutput/zzKeystore".

```bash
├── exampleRawCrtChain.pem
├── splitRawCrtFile.sh
└── zzOutput
    ├── intermediate_single.crt
    ├── rootca_single.crt
    ├── testnode1_chain.crt
    ├── testnode1.key
    ├── testnode1_single.crt
    ├── trustca_chain.crt
    └── zzKeystore
        ├── testnode1.keystore.pkcs12
        └── truststore.pkcs12
```
