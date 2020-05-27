# Overview

## Usage

```bash
./splitCertChainRawFile <raw_crt_chain_file> <node_name>

e.g. ./splitCertChainRawFile exampleRawCrtChain.pem testnode1
```

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
