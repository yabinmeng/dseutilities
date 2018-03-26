## Prerequisites 

1. Linux "expect" utility is installed
```bash
$ sudo apt-get install expect
$ sudo yum install expect
```
2. The local encryption key (e.g. "/etc/opscenter/opsc_system_key" by default) has already been created in advance.
3. Configuration encryption has been activated in "opscenterd.conf"

NOTE: please refer to [document](https://docs.datastax.com/en/opscenter/6.1/opsc/configure/encryptSensitiveConfigValues.html) for procdure description of prerequites 2 and 3 

## Automation Challenge and Utility Overview

After the local encryption key has been created and configuration encryption been activated, the next step is to call the actual confgituraion value encrpytion tool offered by OpsCenter: "opscenter_system_key_tool value". This tool doesn't take any input argument and requires manual entry of the to-be-encrypted value from the command-line console. 

From automation perspective (e.g. Chef or Ansible), this behavior represents a big challenge. The utility introduced here aims to address this challenge by creating a wrapper facility around the original OpsCenter encryption tool "opscenter_system_key_tool value". This utility takes one input parameter as the value to be encrpted and it automatically simulates the double-manual-entry behavior as required by the original tool, through linux "expect" script.

The entry point of this utility is a bash script ***encryptopsc.sh***. The usage and one example is listed below:

```bash
encryptopsc.sh <value_to_be_encrypted>
   
### Example ###
$ ./encryptdse.sh cassandra
JstfB2B219kDcxuqhUaD6Q==
```
