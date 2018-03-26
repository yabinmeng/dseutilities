# Background

This [DSE Document Page](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEncryptProperties.html) describes the procedure of how to encrypt DSE configuration file properties such as the plain password used in dse.yaml/cassandra.yaml file. Briefly speaking, the steps involved in this procedure include:
1. Set up local encryption keys, as per DSE document: https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEncryptLocalKeys.html
2. Int DSE, activate *config_encryption_active* setting and specifying the encryption key file as created in step 1) through setting *config_encryption_key_name* setting. 
3. Call DSE command-line utility **dsetool encryptconfigvalue** to get the encrypted value for the properties (e.g. plain text password) in *cassandr.yaml* and/or *dse.yaml* file that need to be encrypted.
4. Update *cassandr.yaml* and/or *dse.yaml* file and do rolling restart of the DSE cluster.


# Automation Challenge and Utility Overview

Among the above steps, step 3 is a manual process that expects the user to manually enter inputs to the dsetool utility from command line window twice. From procedure automation perspective, e.g. through tools like Chef or Ansible, this step represents a bigger challenge compared with other steps. This utility aims to address this challenge by creating a wrapper facility around "dsetool encryptconfigvalue" that can simulate the twice-manual-entry behavior through "expect" script.
