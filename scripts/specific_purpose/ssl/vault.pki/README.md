## Vault Server Precondition
1. Vault server is initialized and unsealed
```
$ vault operator init
$ vault operator unseal
```
2. Vault PKI secrets engine is enabled and configured for Certificate Revocation List (CRL) and Issuing Certificates Location
```
$ vault secrets enable pki

$ vault write pki/config/urls \
     issuing_certificates="http://10.101.36.12:8200/v1/pki/ca" \
     crl_distribution_points="http://10.101.36.12:8200/v1/pki/crl"
```
3. A self-signed CA certificate (and key) is generated for an allowed common name (CN) (e.g. mydomain.com)
```
$ vault write pki/root/generate/internal common_name=mydomain.com
```
4. A Vault PKI role is created (e.g. dseCluster1CA)
```
$ vault write pki/roles/dseCluster1CA \
     allowed_domains=mydomain.com \
     allow_subdomains=true \
     max_ttl=72h
Success! Data written to: pki/roles/dseCluster1CA
```
5. A Vault token is generated that has the enough priviledge for Vault PKI API call (from the script)


## Description of Vault Configuration File 

The script requires a confiugration to specify key Vault PKI information as below. Note that the specified values need to match the actual VAULT PKI set up as above:
```
ADDR_API=<vault_addr_api>                         (format: <vault_serve_ip>:8200)
TOKEN=<vault_token>
PKI_CERT_ROLE=<vault_pki_role>                    (e.g. dseCluster1CA)
ALLOWED_DOMAIN=<vault_pki_role_parent_domain>     (e.g. mydomain.com)
TTL_IN_HOUR=<valut_certificate_ttl_value>         (e.g. 72h)
```

## Command Execution Example
```
./genVaultPKICert.sh -nlf nodelist -vcfgf vaultcfg
```

The script generates a subfolder called **GeneratedVaultPKICert** under the folder where the command is executed. Among other intermediate step files, tt generates the following final files that need to be copied to the DSE cluster
* One commond truststore file (dseTruststore.pkcs12) that is shared by all nodes in the cluster
* One keystore file (dsenode.<node-ip>.keystore.pkcs12) per DSE node

```
$ tree GeneratedVaultPKICert/
GeneratedVaultPKICert/
├── dseTruststore.pkcs12
├── dsenode.192-168-0-1.crt.signed
├── dsenode.192-168-0-1.key
├── dsenode.192-168-0-1.keystore.pkcs12
├── dsenode.192-168-0-1_vault_pki_raw.json
├── dsenode.192-168-0-2.crt.signed
├── dsenode.192-168-0-2.key
├── dsenode.192-168-0-2.keystore.pkcs12
├── dsenode.192-168-0-2_vault_pki_raw.json
├── dsenode.192-168-0-3.crt.signed
├── dsenode.192-168-0-3.key
├── dsenode.192-168-0-3.keystore.pkcs12
├── dsenode.192-168-0-3_vault_pki_raw.json
└── rootca.crt
```
