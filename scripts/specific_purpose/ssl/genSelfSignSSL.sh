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
ROOTCA_PASS_VAR=dse_rootpass
ROOTCA_ALIAS_VAR=RootCa

ROOT_CA_EXPIRE_DAYS_VAR=3650


###
# Java KeyStore related constants and vairables
# --------------------------------------
# NOTE: Default storetype 'JKS' is not recommended.
#       Otherwise, the following warning message will be gnerated for almost every keytool command:
# --------------------------------------
# Warning:
# The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore <xxx> -destkeystore <yyy> -deststoretype pkcs12"
KEYSTORE_TYPE_JKS=JKS
KEYSTORE_TYPE_PKCS12=PKCS12

KEYSTORE_TYPE_VAR=$KEYSTORE_TYPE_PKCS12
KEYSTORE_FILE_EXT=$(echo "$KEYSTORE_TYPE_VAR" | tr '[:upper:]' '[:lower:]')

# It is a current DSE limitation to use the same password for both keystore and key
TRUSTSTORE_STORE_PASS_VAR="dse_storepss_trust"
TRUSTSTORE_KEY_PASS=$TRUSTSTORE_STORE_PASS_VAR
KEYSTORE_STORE_PASS_VAR="dse_storepass_key"
KEYSTORE_KEY_PASS=$KEYSTORE_STORE_PASS_VAR

TRUSTSTORE_NAME_VAR=dse-truststore.$KEYSTORE_FILE_EXT
KEYSTORE_NAME_BASE_VAR=dse-keystore

PRIV_KEY_EXPIRE_DAYS_VAR=730


### 
# CQLSH Key/Certificate related
CQLSH_KEY_EXPIRE_DAYS_VAR=730


###
# Misc variables
KEY_FILE_EXT_VAR=key
CSR_FILE_EXT_VAR=csr
SIGNED_CRT_FILE_EXT_VAR=crt.signed


###
# Distinguished Name (DN) Fields
#
# - Country
DN_C_VAR=US
# - State
DN_ST_VAR=TX
# - Location
DN_L_VAR=Dallas
# - Organization
DN_O_VAR="Some Corp"
# - Organization Unit
DN_OU_VAR="Some Dept"
# - Common Name (by default, using local node's FQDN name)
DN_CN_VAR=`hostname -A`



###
# Main script logic starts ...
echo
echo "== Create a key/certificate pair for self-signing purposer =="
openssl req -new -x509 -nodes             \
        -keyout $ROOTCA_KEY_FILE          \
        -out $ROOTCA_CERT_FILE            \
        -days $ROOT_CA_EXPIRE_DAYS_VAR    \
        -passout pass:$ROOT_CA_PASS_VAR   \
        -subj "/C=$DN_C_VAR/ST=$DN_ST_VAR/L=$DN_L_VAR/O=$DN_O_VAR/OU=$DN_OU_VAR/CN=$DN_CN_VAR"

echo
echo "== Generate a common \"truststore\" to be shared for all DSE hosts and import self-signed root certificate =="
keytool  -keystore "$TRUSTSTORE_SUBDIR/$TRUSTSTORE_NAME_VAR"   \
         -storetype $KEYSTORE_TYPE_VAR                         \
         -storepass $TRUSTSTORE_STORE_PASS_VAR                 \
         -keypass $TRUSTSTORE_KEY_PASS                         \
         -importcert -file $ROOTCA_CERT_FILE                   \
         -alias $ROOTCA_ALIAS_VAR                              \
         -noprompt

if [[ $1 == "-f" ]]; then
   if [[ -f "$2" ]]; then
      echo
      echo "== Generate \"keystore\"s for all specified DSE host - one keystore per host =="

      while IFS= read -r line
      do
         line2=${line//./-}

         KEYSTORE_FILE="$KEYSTORE_SUBDIR/$KEYSTORE_NAME_BASE_VAR""_${line2}"".$KEYSTORE_FILE_EXT"
         CSR_FILE="$KEYSTORE_CSR_SUBDIR/$KEYSTORE_NAME_BASE_VAR""_${line2}"".$CSR_FILE_EXT_VAR"
         SIGNED_CRT_FILE="$KEYSTORE_CSR_SUBDIR/$KEYSTORE_NAME_BASE_VAR""-${line2}"".$SIGNED_CRT_FILE_EXT_VAR"

         echo "  [Host:  $line]"
         echo "  -- create a keystore with a private key (algorithm: RSA, size: 2048) for DSE server"
         keytool -genkeypair                             \
                 -storetype $KEYSTORE_TYPE_VAR           \
                 -keystore "$KEYSTORE_FILE"              \
                 -storepass "$KEYSTORE_STORE_PASS_VAR"   \
                 -keypass "$KEYSTORE_KEY_PASS"           \
                 -alias "$line"                          \
                 -keyalg RSA                             \
                 -keysize 2048                           \
                 -validity $PRIV_KEY_EXPIRE_DAYS_VAR     \
                 -dname "C=$DN_C_VAR, C=$DN_C_VAR, O=$DN_O_VAR, O=$DN_O_VAR, CN=$line"

         echo
         echo "  -- create a CSR"
         keytool -certreq -file "$CSR_FILE"              \
                 -keystore "$KEYSTORE_FILE"              \
                 -storepass "$KEYSTORE_STORE_PASS_VAR"   \
                 -keypass "$KEYSTORE_KEY_PASS"           \
                 -alias $line

         echo
         echo "  -- sign the certificate"
         openssl x509 -req                            \
                 -CAkey $ROOTCA_KEY_FILE              \
                 -CA $ROOTCA_CERT_FILE                \
                 -in $CSR_FILE                        \
                 -out $SIGNED_CRT_FILE                \
                 -days $PRIV_KEY_EXPIRE_DAYS_VAR      \
                 -CAcreateserial                      \
                 -passin pass:$ROOT_CA_PASS_VAR

         echo
         echo "  -- import RootCA certificate to the keystore"
         keytool -importcert -file "$ROOTCA_CERT_FILE"   \
                 -keystore "$KEYSTORE_FILE"              \
                 -storepass "$KEYSTORE_STORE_PASS_VAR"   \
                 -keypass "$KEYSTORE_KEY_PASS"           \
                 -alias "$ROOTCA_ALIAS_VAR"              \
                 -noprompt

         echo
         echo "  -- import signed certificate to the keystore"
         keytool -importcert -file "$SIGNED_CRT_FILE"    \
                 -keystore "$KEYSTORE_FILE"              \
                 -storepass "$KEYSTORE_STORE_PASS_VAR"   \
                 -keypass "$KEYSTORE_KEY_PASS"           \
                 -alias "$line"                          \
                 -noprompt

         echo
         echo "  -- create a pair of key (algorithm: RSA, size: 2048) and CSR for CQLSH client"
         openssl req -new -nodes                      \
                 -newkey rsa:2048                     \
                 -keyout "$CQLSH_SUBDIR/cqlsh_$line2"".$KEY_FILE_EXT_VAR"  \
                 -out "$CQLSH_SUBDIR/cqlsh_$line2"".$CSR_FILE_EXT_VAR"     \
                 -days $CQLSH_KEY_EXPIRE_DAYS_VAR     \
                 -subj "/C=$DN_C_VAR/ST=$DN_ST_VAR/L=$DN_L_VAR/O=$DN_O_VAR/OU=$DN_OU_VAR/CN=$line"

         echo
         echo "  -- sign CQLSH certificate"
         openssl x509 -req                            \
                 -CAkey $ROOTCA_KEY_FILE              \
                 -CA $ROOTCA_CERT_FILE                \
                 -in "$CQLSH_SUBDIR/cqlsh_$line2"".$CSR_FILE_EXT_VAR"         \
                 -out "$CQLSH_SUBDIR/cqlsh_$line2"".$SIGNED_CRT_FILE_EXT_VAR" \
                 -days $CQLSH_KEY_EXPIRE_DAYS_VAR     \
                 -CAcreateserial                      \
                 -passin pass:$ROOT_CA_PASS_VAR


         echo
         echo
      done < "$2"
   else
      echo
      echo "ERROR: The provided file doesn't exist! Please provide a valid file name!"
      echo
      exit 20
   fi
else
   usage
   exit 30
fi