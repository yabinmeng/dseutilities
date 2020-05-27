#! /bin/bash

usage() {
   echo
   echo "Usage: splitRawCrtFile.sh [-h | <example_raw_cert_chain_file> <node_name>]"
   echo
}

if [[ $1 == "-h" || $# -ne 2 ]]; then
   usage
   exit 10
fi

OUTPUTDIR="zzOutput"
KEYSTORE_DIR="$OUTPUTDIR"/"zzKeystore"

mkdir -p ./$KEYSTORE_DIR

# Node key
cat $1 | awk '/BEGIN PRIVATE KEY/,/END PRIVATE KEY/' > ./$OUTPUTDIR/$2.key

ALL_CERTS=`openssl crl2pkcs7 -nocrl -certfile $1 | openssl pkcs7 -print_certs`

# Node certificate
echo "$ALL_CERTS" | awk '/subject.*CN=.*.com/,/END CERTIFICATE/' | tail -n +3 > ./$OUTPUTDIR/"$2""_single.crt"

# Intermediate certificate
echo "$ALL_CERTS" | awk '/subject.*CN=DC1IntermediateCA01/,/END CERTIFICATE/' | tail -n +3 > ./$OUTPUTDIR/intermediate_single.crt

# Root certificate
echo "$ALL_CERTS" | awk '/subject.*CN=DC1RootCA01/,/END CERTIFICATE/' | tail -n +3 > ./$OUTPUTDIR/rootca_single.crt

# Form public cert chain (without bag attributes)
cat ./$OUTPUTDIR/intermediate_single.crt ./$OUTPUTDIR/rootca_single.crt > ./$OUTPUTDIR/trustca_chain.crt

# Form node cert chain (without bag attributes)
cat ./$OUTPUTDIR/"$2""_single.crt" ./$OUTPUTDIR/trustca_chain.crt > ./$OUTPUTDIR/"$2""_chain.crt"

# Import node key and node cert chain into the keystore file (of PKCS12 type)
openssl pkcs12 -export -name $2 \
      -in ./$OUTPUTDIR/"$2""_chain.crt" -inkey ./$OUTPUTDIR/$2.key \
      -out ./$KEYSTORE_DIR/$2.keystore.pkcs12 \
      -password pass:casspass20

# Import public cert chain into the truststore (of PKCS12 type)
keytool -delete -import -noprompt -alias trustca \
   -storetype PKCS12 \
   -file ./$OUTPUTDIR/trustca_chain.crt \
   -keystore ./$KEYSTORE_DIR/truststore.pkcs12 \
   -storepass casspass20