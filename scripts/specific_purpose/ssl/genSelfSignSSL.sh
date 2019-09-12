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


# Create desired folder structure under the current folder
WORKING_HOMEDIR=./SelfSignedSSL
ROOTCA_SUBDIR=$WORKING_HOMEDIR/root
TRUSTSTORE_SUBDIR=$WORKING_HOMEDIR/truststore
KEYSTORE_SUBDIR=$WORKING_HOMEDIR/keystore
KEYSTORE_CSR_SUBDIR=$KEYSTORE_SUBDIR/csr

mkdir -p $ROOTCA_SUBDIR
mkdir -p $TRUSTSTORE_SUBDIR
mkdir -p $KEYSTORE_SUBDIR
mkdir -p $KEYSTORE_CSR_SUBDIR


# ROOT CA related constants
ROOTCA_KEY_FILE=$ROOTCA_SUBDIR/rootca.key
ROOTCA_CERT_FILE=$ROOTCA_SUBDIR/rootca.crt
ROOTCA_PASS=dse_rootpass
ROOTCA_ALIAS=RootCa

# Other constants
KEYSTORE_FILE_EXT=jks
CSR_FILE_EXT=csr
SIGNED_CRT_FILE_EXT=crt.signed
TRUSTSTORE_NAME=dse-truststore.$KEYSTORE_FILE_EXT
KEYSTORE_NAME_BASE=dse-keystore

# It is a current DSE limitation to use the same password for both keystore and key
TRUSTSTORE_STORE_PASS="dse_storepss_trust"
TRUSTSTORE_KEY_PASS=$TRUSTSTORE_STORE_PASS
KEYSTORE_STORE_PASS="dse_storepass_key"
KEYSTORE_KEY_PASS=$KEYSTORE_STORE_PASS


# Distinguished Name (DN) Fields
#
# - Country
DN_C=US
# - State
DN_ST=TX
# - Location
DN_L=Dallas
# - Organization
DN_O="Some Corp"
# - Organization Unit
DN_OU="Some Dept"
# - Common Name (by default, using local node's FQDN name)
DN_CN=`hostname -A`

# By default, generate a certificate that expires in 2 years.
# Change this value if needed
ROOT_CA_EXPIRE_DAYS=3650
PRIV_KEY_EXPIRE_DAYS=730


echo
echo "== Create a key/certificate pair for self-signing purposer =="
openssl req -new -x509 -nodes          \
        -keyout $ROOTCA_KEY_FILE       \
        -out $ROOTCA_CERT_FILE         \
        -days $ROOT_CA_EXPIRE_DAYS     \
        -passout pass:$ROOT_CA_PASS    \
        -subj "/C=$DN_C/ST=$DN_ST/L=$DN_L/O=$DN_O/OU=$DN_OU/CN=$DN_CN"

echo
echo "== Generate a common \"truststore\" to be shared for all DSE hosts and import self-signed root certificate =="
keytool  -keystore "$TRUSTSTORE_SUBDIR/$TRUSTSTORE_NAME" \
         -storetype JKS                                  \
         -storepass $TRUSTSTORE_STORE_PASS               \
         -keypass $TRUSTSTORE_KEY_PASS                   \
         -importcert -file $ROOTCA_CERT_FILE             \
         -alias $ROOTCA_ALIAS                            \
         -noprompt 

if [[ $1 == "-f" ]]; then
   if [[ -f "$2" ]]; then
      echo
      echo "== Generate \"keystore\"s for all specified DSE host - one keystore per host =="

      while IFS= read -r line
      do
         line2=${line//./-}

         KEYSTORE_FILE="$KEYSTORE_SUBDIR/$KEYSTORE_NAME_BASE""_${line2}"".$KEYSTORE_FILE_EXT"
         CSR_FILE="$KEYSTORE_CSR_SUBDIR/$KEYSTORE_NAME_BASE""_${line2}"".$CSR_FILE_EXT"
         SIGNED_CRT_FILE="$KEYSTORE_CSR_SUBDIR/$KEYSTORE_NAME_BASE""-${line2}"".$SIGNED_CRT_FILE_EXT"

         echo "  [Host:  $line]"
         echo
         echo "  -- create a keystore with a private key (algorithm: RSA, size: 2048)"
         keytool -genkeypair                          \
                 -keystore "$KEYSTORE_FILE"           \
                 -storepass "$KEYSTORE_STORE_PASS"    \
                 -keypass "$KEYSTORE_KEY_PASS"        \
                 -alias "$line"                       \
                 -keyalg RSA                          \
                 -keysize 2048                        \
                 -validity $PRIV_KEY_EXPIRE_DAYS      \
                 -dname "CN=$line, OU=$DN_OU, O=$DN_O, ST=$DN_ST, C=$DN_C"

         echo
         echo "  -- create a CSR"
         keytool -certreq -file "$CSR_FILE"           \
                 -keystore "$KEYSTORE_FILE"           \
                 -storepass "$KEYSTORE_STORE_PASS"    \
                 -keypass "$KEYSTORE_KEY_PASS"        \
                 -alias $line

         echo
         echo "  -- sign the certificate"
         openssl x509 -req                            \
                 -CAkey $ROOTCA_KEY_FILE              \
                 -CA $ROOTCA_CERT_FILE                \
                 -in $CSR_FILE                        \
                 -out $SIGNED_CRT_FILE                \
                 -days $PRIV_KEY_EXPIRE_DAYS          \
                 -CAcreateserial                      \
                 -passin pass:$ROOT_CA_PASS

         echo
         echo "  -- import RootCA certificate to the keystore"
         keytool -importcert -file "$ROOTCA_CERT_FILE"   \
                 -keystore "$KEYSTORE_FILE"              \
                 -storepass "$KEYSTORE_STORE_PASS"       \
                 -keypass "$KEYSTORE_KEY_PASS"           \
                 -alias "$ROOTCA_ALIAS"                  \
                 -noprompt 

         echo
         echo "  -- import signed certificate to the keystore"
         keytool -importcert -file "$SIGNED_CRT_FILE"    \
                 -keystore "$KEYSTORE_FILE"              \
                 -storepass "$KEYSTORE_STORE_PASS"       \
                 -keypass "$KEYSTORE_KEY_PASS"           \
                 -alias "$line"                          \
                 -noprompt

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
   exit 20
fi