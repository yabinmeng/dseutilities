
**Vault Configuration File Content** 
```
ADDR_API=<vault_addr_api>                         (e.g. http://<vault_serve_ip>:8200)
TOKEN=<vault_token>
PKI_CERT_ROLE=<vault_pki_role>                    (e.g. dseCluster1CA)
ALLOWED_DOMAIN=<vault_pki_role_parent_domain>     (e.g. mydomain.com)
TTL_IN_HOUR=<valut_certificate_ttl_value>         (e.g. 72h)
```

The PKI_CERT_ROLE, ALLOWED_DOMAIN, TTL_IN_HOUR need to match the atual Vault PKI role that is created on the Vault server
```
$ vault write pki/roles/dseCluster1CA \
>     allowed_domains=mydomain.com \
>     allow_subdomains=true \
>     max_ttl=72h
Success! Data written to: pki/roles/dseCluster1CA
```
