## Prerequisites 

1. Linux "expect" utility is installed
```bash
$ sudo apt-get install expect
$ sudo yum install expect
```
2. The local encryption key (e.g. "/etc/dse/conf/system_key" by default) has already been created in advance.
3. Configuration encryption has been activated in "dse.yaml" (config_encryption_active: true)

NOTE: please refer to [document](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEncryptConfig.html) for procdure description of prerequites 2 and 3 

## Automation Challenge and Utility Overview

After the local encryption key has been created, you can execute the DSE encrpytion tool("dsetool encryptconfigvalue") to encrypt the configuration value of interest. This tool doesn't take any input argument and requires manual entry (twice) of the to-be-encrypted value from the command-line console. 

From automation perspective (e.g. Chef or Ansible), this behavior represents a big challenge. The utility introduced here aims to address this challenge by creating a wrapper facility around the original DSE encryption tool "dsetool encryptconfigvalue". This utility takes one input parameter as the value to be encrpted and it automatically simulates the double-manual-entry behavior as required by the original tool, through linux "expect" script.

The entry point of this utility is a bash script ***encryptdse.sh***. The usage and one example is listed below:
```bash
encryptdse.sh <value_to_be_encrypted>
   
### Example ###
$ ./encryptdse.sh cassandra
kGDDkOFO3YAtFQabiKXcNA==
```
