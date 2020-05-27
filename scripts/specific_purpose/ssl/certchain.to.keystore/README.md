## Usage
```
./splitCertChainRawFile <raw_crt_chain_file> <node_name>

e.g. ./splitCertChainRawFile exampleRawCrtChain.pem testnode1
```

## Example Raw Cert Chain PEM File Structure
```
Bag Attributes
    Microsoft Local Key set: <No Values>
    localKeyID: 01 00 00 00
    Microsoft CSP Name: Microsoft RSA SChannel Cryptographic Provider
    friendlyName: le-SCCMclientauth-6adca2b4-38bb-4f33-a285-8e05e69eb154
Key Attributes
    X509v3 Key Usage: 10
-----BEGIN PRIVATE KEY-----
... ...
-----END PRIVATE KEY-----
Bag Attributes
    localKeyID: 01 00 00 00
    1.3.6.1.4.1.311.17.3.20: 66 1C BA 8A A3 EB 78 F1 AE 19 96 6B 87 B2 65 4B F8 CC 03 81
    1.3.6.1.4.1.311.17.3.71: 44 00 43 00 32 00 43 00 45 00 52 00 54 00 43 00 41 00 32 00 30 00 32 00 2E 00 64 00 63 00 31 00 2E 00 67 00 72 00 65 00 65 00 6E 00 64 00 6F 00 74 00 63 00 6F 00 72 00 70 00 2E 00 63 00 6F 00 6D 00 00 00
    1.3.6.1.4.1.311.17.3.87: 00 00 00 00 00 00 00 00 02 00 00 00 20 00 00 00 02 00 00 00 6C 00 64 00 61 00 70 00 3A 00 00 00 7B 00 35 00 34 00 31 00 41 00 43 00 34 00 43 00 39 00 2D 00 36 00 35 00 44 00 33 00 2D 00 34 00 44 00 34 00 30 00 2D 00 39 00 44 00 35 00 43 00 2D 00 45 00 46 00 42 00 33 00 34 00 32 00 34 00 38 00 44 00 42 00 30 00 30 00 7D 00 00 00 44 00 43 00 32 00 43 00 45 00 52 00 54 00 43 00 41 00 32 00 30 00 32 00 2E 00 64 00 63 00 31 00 2E 00 67 00 72 00 65 00 65 00 6E 00 64 00 6F 00 74 00 63 00 6F 00 72 00 70 00 2E 00 63 00 6F 00 6D 00 5C 00 44 00 43 00 31 00 49 00 6E 00 74 00 65 00 72 00 6D 00 65 00 64 00 69 00 61 00 74 00 65 00 43 00 41 00 30 00 31 00 00 00 31 00 35 00 30 00 34 00 35 00 31 00 31 00 00 00
subject=/C=US/ST=CA/L=Pasadena/O=Green Dot Corp/OU=IT/CN=testnode1.dc1.abccorp.com
issuer=/DC=com/DC=greendotcorp/DC=dc1/CN=DC1IntermediateCA01
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
Bag Attributes
    1.3.6.1.4.1.311.17.3.20: CE 89 0A CF 26 C8 6D 48 38 54 31 DB 7D 2B 7A 14 81 E5 EC 74
subject=/DC=com/DC=greendotcorp/DC=dc1/CN=DC1RootCA01
issuer=/DC=com/DC=greendotcorp/DC=dc1/CN=DC1RootCA01
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
Bag Attributes
    1.3.6.1.4.1.311.17.3.20: B5 BE 56 37 01 9B 64 88 6B 24 5A 2F 9D 3E 3F 7C B4 83 FA 93
subject=/DC=com/DC=greendotcorp/DC=dc1/CN=DC1IntermediateCA01
issuer=/DC=com/DC=greendotcorp/DC=dc1/CN=DC1RootCA01
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
Bag Attributes
    1.3.6.1.4.1.311.17.3.20: B5 BE 56 37 01 9B 64 88 6B 24 5A 2F 9D 3E 3F 7C B4 83 FA 93
subject=/DC=com/DC=greendotcorp/DC=dc1/CN=DC1IntermediateCA01
issuer=/DC=com/DC=greendotcorp/DC=dc1/CN=DC1RootCA01
-----BEGIN CERTIFICATE-----
```
