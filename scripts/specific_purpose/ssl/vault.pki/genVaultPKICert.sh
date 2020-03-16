#! /bin/bash


#
# NOTE: this script is used for generating self signed ceritificates to be used
#       when DSE client-to-server and/or server-to-server SSL is enabled
#
#


usage() {
   echo
   echo "Usage: genVaultPKICert.sh [-h | "
   echo "                           -nlf <dsenode_hostname_or_ip_list> -vcfgf <vault_configuration"
   echo "       -h : display command usage"
   echo "       -nlf: A file that specifies DSE ndoe list (hostname or IP)"
   echo "       -vcfgf: A file that specifies Vault server connection for PKI certificate generation"
   echo
}

if [[ $# -eq 0 || $# -gt 4 || "$1" == "-h" ||
      "$1" != "-nlf" || "$3" != "-vcfgf" ]]; then
   usage
   exit 10
fi

NODE_LIST_FILE="$2"
if [[ ! -f $NODE_LIST_FILE ]]; then
   echo "The specified node list file does NOT exist!"
   exit
fi

VAULT_CFG_FILE="$4"
if [[ ! -f $NODE_LIST_FILE ]]; then
   echo "The specified vault configuration file does NOT exist!"
   exit
fi


while IFS="=" read -r key value; do
   key=$(echo "$key" | tr '[:lower:]' '[:upper:]')
   if [[ "$key" == "ADDR_API" ]]; then
      VAULT_API_ADDR=$value
   elif [[ "$key" == "TOKEN" ]]; then
      VAULT_TOKEN=$value
   elif [[ "$key" == "PKI_CERT_ROLE" ]]; then
      VAULT_PKI_ROLE=$value
   elif [[ "$key" == "ALLOWED_DOMAIN" ]]; then
      VAULT_PKI_PARENT_DOMAIN=$value
   elif [[ "$key" == "TTL_IN_HOUR" ]]; then
      VAULT_CERT_TTL_IN_HOUR=$value
   fi
done < $VAULT_CFG_FILE

#echo $VAULT_API_ADDR
#echo $VAULT_TOKEN
#echo $VAULT_PKI_ROLE
#echo $VAULT_PKI_PARENT_DOMAIN


###
# Create desired folder structure under the current folder
WORKING_HOMEDIR=./GeneratedVaultPKICert
mkdir -p $WORKING_HOMEDIR


###
# It is a current DSE limitation to use the same password for both keystore and key
KEYSTORE_STOREPASS="MyKeyStorePass"
TRUSTSTORE_STOREPASS="MyTrustStorePass"

CERT_FORMAT=PKCS12
CERT_FILE_EXT=$(echo "$CERT_FORMAT" | tr '[:upper:]' '[:lower:]')

#SED_NEWLINE_STR="'s/\\n/\
#/g'"


###
# Main script logic starts ...
echo
echo
echo "== 1. Call Vault PKI API to get signed certificates for all specified DSE hosts =="

while IFS= read -r line
do
   line2=${line//./-}

   DSENODE_NAME="dsenode.$line2"
   RAW_PKI_CERT_FILENAME="$WORKING_HOMEDIR/$DSENODE_NAME""_vault_pki_raw.json"

   echo
   echo "   ## DSE Host:  $line ##"
   echo "      >> 1.1. Call Vault PKI API for certificate generation"

   apiCallCmdStr="
   curl --header \"X-Vault-Token: $VAULT_TOKEN\" \
        --request POST \
        --data '{\"common_name\": \"$DSENODE_NAME.mydomain.com\", \"ttl\": \"$VAULT_CERT_TTL_IN_HOUR\"}' \
        $VAULT_API_ADDR/v1/pki/issue/$VAULT_PKI_ROLE"

   #echo $apiCallCmdStr
   eval $apiCallCmdStr > $RAW_PKI_CERT_FILENAME

   echo "      >> 1.2. Parse out the signed certificate and the private key"
   DSENODE_SIGNED_CRT="$WORKING_HOMEDIR/$DSENODE_NAME.crt.signed"
   DSENODE_PRIV_KEY="$WORKING_HOMEDIR/$DSENODE_NAME.key"
   DSENODE_KEYSTORE="$WORKING_HOMEDIR/$DSENODE_NAME.keystore"

   jq -r '.data.certificate' $RAW_PKI_CERT_FILENAME > $DSENODE_SIGNED_CRT
   jq -r '.data.private_key' $RAW_PKI_CERT_FILENAME > $DSENODE_PRIV_KEY

   echo "      >> 1.3. Generate a PKCS12 keystore and import the signed certificate and the private key"

   opensslCmdStr="
   openssl pkcs12 -export -name $DSENODE_NAME \
      -in $DSENODE_SIGNED_CRT -inkey $DSENODE_PRIV_KEY \
      -out $DSENODE_KEYSTORE.$CERT_FILE_EXT \
      -password pass:$KEYSTORE_STOREPASS"

   #echo $opensslCmdStr
   eval $opensslCmdStr

done < "$NODE_LIST_FILE"

echo
echo "== 2. Create a common truststore and import the signing(root) certificate =="

jq -r '.data.issuing_ca' $RAW_PKI_CERT_FILENAME > "$WORKING_HOMEDIR/rootca.crt"

TRUSTSTORE_NAME="$WORKING_HOMEDIR/dseTruststore.$CERT_FILE_EXT"

keytoolCmdStr="
keytool -delete -import -noprompt -alias rootca \
   -storetype $CERT_FORMAT \
   -file $WORKING_HOMEDIR/rootca.crt \
   -keystore $TRUSTSTORE_NAME \
   -storepass $TRUSTSTORE_STOREPASS"

#echo $keytoolCmdStr
eval $keytoolCmdStr

echo
echo