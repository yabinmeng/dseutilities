#! /bin/bash


#
# NOTE: this script is used for generating self signed ceritificates to be used
#       when DSE client-to-server and/or server-to-server SSL is enabled
#
#


usage() {
   echo
   echo "Usage: genSelfSignSSL.sh [-h | -f <hostname_or_ip_list_file>]"
   echo
}

if [[ $# -eq 0 || $# -gt 2 || $1 == "-h" ]]; then
   usage
   exit 10
fi


###
# Create desired folder structure under the current folder
WORKING_HOMEDIR_VAR=./SelfSignedSSL
ROOTCA_SUBDIR=$WORKING_HOMEDIR_VAR/rootca
CQLSH_SUBDIR=$WORKING_HOMEDIR_VAR/cqlsh
TRUSTSTORE_SUBDIR=$WORKING_HOMEDIR_VAR/truststore
KEYSTORE_SUBDIR=$WORKING_HOMEDIR_VAR/keystore
KEYSTORE_CSR_SUBDIR=$KEYSTORE_SUBDIR/csr

mkdir -p $ROOTCA_SUBDIR
mkdir -p $CQLSH_SUBDIR
mkdir -p $TRUSTSTORE_SUBDIR
mkdir -p $KEYSTORE_SUBDIR
mkdir -p $KEYSTORE_CSR_SUBDIR


###
# ROOT CA related constants and vrariables
ROOTCA_KEY_FILE=$ROOTCA_SUBDIR/rootca.key
ROOTCA_CERT_FILE=$ROOTCA_SUBDIR/rootca.crt
ROOTCA_PASS_VAR=MyRootCAPass
ROOTCA_ALIAS_VAR=RootCA
ROOTCA_CONFIG_FILE_NAME=rootca.conf

ROOT_CA_EXPIRE_DAYS_VAR=3650


###
# Java KeyStore related constants and vairables
# --------------------------------------
# NOTE: Default storetype 'JKS' is not recommended.
#       Otherwise, the following warning message will be gnerated for almost every keytool command:
# --------------------------------------
# Warning:
# The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore <xxx> -destkeystore <yyy> -deststoretype pkcs12"
#KEYSTORE_TYPE_VAR=PKCS12
KEYSTORE_TYPE_VAR=JKS
KEYSTORE_FILE_EXT=$(echo "$KEYSTORE_TYPE_VAR" | tr '[:upper:]' '[:lower:]')

# It is a current DSE limitation to use the same password for both keystore and key
TRUSTSTORE_STOREPASS_VAR="MyTrustStorePass"
TRUSTSTORE_KEYPASS=$TRUSTSTORE_STOREPASS_VAR
KEYSTORE_STOREPASS_VAR="MyKeyStorePass"
KEYSTORE_KEYPASS=$KEYSTORE_STOREPASS_VAR

TRUSTSTORE_NAME_VAR=dseTruststore.$KEYSTORE_FILE_EXT
KEYSTORE_NAME_BASE_VAR=dseKeystore

PRIV_KEY_EXPIRE_DAYS_VAR=730


### 
# CQLSH Key/Certificate related
CQLSH_KEY_EXPIRE_DAYS_VAR=730


###
# Misc variables
KEY_FILE_EXT_VAR=key
CSR_FILE_EXT_VAR=csr
SIGNED_CRT_FILE_EXT_VAR=crt.signed

# Distinguished Name (DN) Fields
# - Country
DN_C_VAR=US
# - State
DN_ST_VAR=TX
# - Location
DN_L_VAR=Dallas
# - Organization
DN_O_VAR=DataStax
# - Organization Unit
DN_OU_VAR=MyTestCluster
# - Common Name (by default, using local node's FQDN name)
DN_CN_VAR=


# Generate file rootca.conf
genRootCAConf() {
   echo "[ req ]" > $ROOTCA_CONFIG_FILE_NAME
   echo "distinguished_name  = req_distinguished_name" >> $ROOTCA_CONFIG_FILE_NAME
   echo "prompt              = no" >> $ROOTCA_CONFIG_FILE_NAME
   echo "output_password     = $ROOTCA_PASS_VAR" >> $ROOTCA_CONFIG_FILE_NAME
   echo "default_bits        = 2048" >> $ROOTCA_CONFIG_FILE_NAME
   echo "" >> $ROOTCA_CONFIG_FILE_NAME
   echo "[ req_distinguished_name ]" >> $ROOTCA_CONFIG_FILE_NAME
   echo "C                   = $DN_C_VAR" >> $ROOTCA_CONFIG_FILE_NAME
   echo "O                   = $DN_O_VAR" >> $ROOTCA_CONFIG_FILE_NAME
   echo "OU                  = $DN_OU_VAR" >> $ROOTCA_CONFIG_FILE_NAME
   echo "CN                  = $1" >> $ROOTCA_CONFIG_FILE_NAME
}



###
# Main script logic starts ...
echo
echo "== STEP 1 :: Create a key/certificate pair for self-signing purpose =="
# - generate the required config file
genRootCAConf $ROOTCA_ALIAS_VAR
openssl req -config $ROOTCA_CONFIG_FILE_NAME \
        -new -x509 -nodes                    \
        -keyout $ROOTCA_KEY_FILE             \
        -out $ROOTCA_CERT_FILE               \
        -days $ROOT_CA_EXPIRE_DAYS_VAR
        #-subj "/C=$DN_C_VAR/ST=$DN_ST_VAR/L=$DN_L_VAR/O=$DN_O_VAR/OU=$DN_OU_VAR/CN=$DN_CN_VAR"

echo
echo "== STEP 2 :: Generate a common \"truststore\" to be shared for all DSE hosts and import self-signed root certificate =="
TRUSTSTORE_FILE="$TRUSTSTORE_SUBDIR/$TRUSTSTORE_NAME_VAR"
keytool -import -trustcacerts -file $ROOTCA_CERT_FILE \
        -keystore "$TRUSTSTORE_FILE"         \
        -storetype "$KEYSTORE_TYPE_VAR"      \
        -storepass $TRUSTSTORE_STOREPASS_VAR \
        -keypass $TRUSTSTORE_KEYPASS         \
        -alias $ROOTCA_ALIAS_VAR             \
        -noprompt


if [[ $1 == "-f" ]]; then
   if [[ -f "$2" ]]; then
      echo
      echo "== STEP 3 :: Generate \"keystore\"s and CQLSH certificates for all specified DSE hosts =="

      while IFS= read -r line
      do
         line2=${line//./-}

         KEYSTORE_FILE="$KEYSTORE_SUBDIR/$KEYSTORE_NAME_BASE_VAR""_${line2}"".$KEYSTORE_FILE_EXT"
         CSR_FILE="$KEYSTORE_CSR_SUBDIR/$KEYSTORE_NAME_BASE_VAR""_${line2}"".$CSR_FILE_EXT_VAR"
         SIGNED_CRT_FILE="$KEYSTORE_CSR_SUBDIR/$KEYSTORE_NAME_BASE_VAR""-${line2}"".$SIGNED_CRT_FILE_EXT_VAR"

         echo "   [Host:  $line]"
         echo "   >> (3.1) create a keystore with a private key (algorithm: RSA, size: 2048) for DSE server"
         keytool -genkeypair -keyalg RSA -keysize 2048 \
                 -keystore "$KEYSTORE_FILE"           \
                 -storetype "$KEYSTORE_TYPE_VAR"      \
                 -storepass "$KEYSTORE_STOREPASS_VAR" \
                 -keypass "$KEYSTORE_KEYPASS"         \
                 -alias "$line"                       \
                 -validity $PRIV_KEY_EXPIRE_DAYS_VAR  \
                 -dname "C=$DN_C_VAR, O=$DN_O_VAR, OU=$DN_OU_VAR, CN=$line"

         echo
         echo "   >> (3.2) create a CSR"
         keytool -certreq -file "$CSR_FILE"           \
                 -keystore "$KEYSTORE_FILE"           \
                 -storepass "$KEYSTORE_STOREPASS_VAR" \
                 -keypass "$KEYSTORE_KEYPASS"         \
                 -alias $line

         echo
         echo "   >> (3.3) sign the certificate"
         openssl x509 -req                         \
                 -CA $ROOTCA_CERT_FILE             \
                 -CAkey $ROOTCA_KEY_FILE           \
                 -in $CSR_FILE                     \
                 -out $SIGNED_CRT_FILE             \
                 -days $PRIV_KEY_EXPIRE_DAYS_VAR   \
                 -CAcreateserial

         echo
         echo "   >> (3.4) import RootCA certificate to the keystore"
         keytool -import -trustcacerts -file "$ROOTCA_CERT_FILE" \
                 -keystore "$KEYSTORE_FILE"           \
                 -storepass "$KEYSTORE_STOREPASS_VAR" \
                 -keypass "$KEYSTORE_KEYPASS"         \
                 -alias "$ROOTCA_ALIAS_VAR"           \
                 -noprompt

         echo
         echo "   >> (3.5) import signed certificate to the keystore"
         keytool -import -trustcacerts -file "$SIGNED_CRT_FILE" \
                 -keystore "$KEYSTORE_FILE"           \
                 -storepass "$KEYSTORE_STOREPASS_VAR" \
                 -keypass "$KEYSTORE_KEYPASS"         \
                 -alias "$line"                       \
                 -noprompt

         echo
         echo "   >> (3.6) create a pair of key (algorithm: RSA, size: 2048) and CSR for CQLSH client"
         openssl req -new -nodes                      \
                 -newkey rsa:2048                     \
                 -keyout "$CQLSH_SUBDIR/cqlsh_$line2"".$KEY_FILE_EXT_VAR"  \
                 -out "$CQLSH_SUBDIR/cqlsh_$line2"".$CSR_FILE_EXT_VAR"     \
                 -days $CQLSH_KEY_EXPIRE_DAYS_VAR     \
                 -subj "/C=$DN_C_VAR/ST=$DN_ST_VAR/L=$DN_L_VAR/O=$DN_O_VAR/OU=$DN_OU_VAR/CN=$line"

         echo
         echo "   >> (3.7) sign CQLSH certificate"
         openssl x509 -req                            \
                 -CAkey $ROOTCA_KEY_FILE              \
                 -CA $ROOTCA_CERT_FILE                \
                 -in "$CQLSH_SUBDIR/cqlsh_$line2"".$CSR_FILE_EXT_VAR"         \
                 -out "$CQLSH_SUBDIR/cqlsh_$line2"".$SIGNED_CRT_FILE_EXT_VAR" \
                 -days $CQLSH_KEY_EXPIRE_DAYS_VAR     \
                 -CAcreateserial


         echo
         echo
      done < "$2"
   else
      echo
      echo "ERROR: The provided file doesn't exist! Please provide a valid file name!"
      echo
      exit 30
   fi
else
   usage
   exit 40
fi
