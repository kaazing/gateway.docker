#!/bin/bash
#
###########################################################
#
# Script to generate keystore and truststore for use with
# Kaazing VPA GW
#
# Author: arnaldo.roldan@gmail.com
#   Date: 07.09.15
#
###########################################################
#

# Enable debug mode 
case $1 in 
   -d*|-D* ) echo "Debug mode enabled" ; DEBUG="true" ;;
         * ) DEBUG="false";;
esac

# Parameters
MYNAME=$1
MYALIAS=$2
MYFQDN=$3
MYLOCALNAME=$4
MYPRIVIPADDR=$5
MYPUBIPADDR=$6
ALTDNS=$7 ; [ "$ALTDNS" != "NA" ] && MYALTDNS=",DNS:${ALTDNS}" || MYALTDNS=""

if [ "${DEBUG}" = "true" ]
then 
   echo "   MYNAME: $MYNAME"
   echo "  MYALIAS: $MYALIAS"
   echo "   MYFQDN: $MYFQDN"
   echo "MYLOCNAME: $MYLOCALNAME"
   echo " MYPRIVIP: $MYPRIVIPADDR"
   echo "MYPUBIPAD: $MYPUBIPADDR"
   echo "   ALTDNS: $ALTDNS"
   echo " MYALTDNS: $MYALTDNS"
fi

MYPASSWD="ab987c"
CAALIAS="kwicca"
DNAME="C=US, ST=California, O=Kaazing Corporation, OU=Operations, CN=Kaazing Operations/emailAddress=support@kaazing.com" 
MYLDAPSPEC="CN=${MYPUBIPADDR}, OU=Domain Control Validated, O=${MYFQDN}, UID=kaazing"
MYDNSSPEC="DNS:${MYFQDN},IP:${MYPRIVIPADDR},DNS:${MYLOCALNAME}${MYALTDNS}"
KEYALG='RSA'
KEYTOOLCMD="/usr/bin/keytool -v"
#
CONFDIR="/kaazing-gateway/conf"          # Home of GW config files
SCRIPT=$(readlink -f "$0")               # Full path to this executable
SCRIPTDIR=$(dirname "$SCRIPT")           # Directory where this script is located
STORESDIR="${SCRIPTDIR}/stores"          # Source for keystore / tuststore templates
TARGETDIR="${SCRIPTDIR}/target"          # Destination for updated keytstore / truststore files
TMPDIR="${SCRIPTDIR}/tmp"	         # Place where we do all of our work
#
TMP_TRUSTSTORE="truststore-temp.db"
TMP_KEYSTORE="keystore-temp.db"
#
#####################################################################
# Following used for alerting user of key information
#####################################################################
LTGREEN='\033[38;5;40m'
YELLOW='\033[1;33m'
ORANGE='\033[38;5;202m'
LTORANGE='\033[38;5;216m'
RED='\033[0;31m'
CYAN='\033[0;36m'
CYANBACK='\033[0;46m'
BLINK='\033[33;5m'
NC='\033[0m'            # Switch Back to Default Text Color
ALERT=${ORANGE}         # Default Alert Color
CALLOUT=${ORANGE}       # Default Callout Color
PAUSE=${ORANGE}         # Default Pause Color

###########################################################
# Main routine - called at bottom of file
###########################################################
main() {

   copy_stores             ; if [ "$DEBUG" = "true" ] ; then pause ; fi
   create_ca               ; if [ "$DEBUG" = "true" ] ; then pause ; fi
   create_host_cert        ; if [ "$DEBUG" = "true" ] ; then pause ; fi
   import_ca_to_truststore ; if [ "$DEBUG" = "true" ] ; then pause ; fi
   import_cert_to_keystore ; if [ "$DEBUG" = "true" ] ; then pause ; fi
   create_pem              ; if [ "$DEBUG" = "true" ] ; then pause ; fi
   copy_stores_to_conf     ; if [ "$DEBUG" = "true" ] ; then pause ; fi
   cleanup
}


pause() {
   echo "--------------------------------------------"
   read -p "Press any key to continue ..." NOOP
   echo "--------------------------------------------"
}

#####################################################################
# Alert user of important information
#####################################################################
alert() {
   printf "${ALERT}%s${NC}\n" "$1"
}

###########################################################
# Start w/ fresh copy of the keystore & truststore
###########################################################
copy_stores() {
   #echo ""
   #echo "-------------------------------------"
   [ "${DEBUG}" = "true" ] && alert "Copying template stores into place ..."
   cd ${TMPDIR}
   cp ${STORESDIR}/keystore.db   ${TMPDIR}/${TMP_KEYSTORE}
   cp ${STORESDIR}/truststore.db ${TMPDIR}/${TMP_TRUSTSTORE}
   cp ${STORESDIR}/keystore.pw   ${TMPDIR}/.
   cp ${STORESDIR}/keystore.pw   ${TARGETDIR}/.

   [ "$DEBUG" = "true" ] && ls -l
}

###########################################################
# Create self signed CA
###########################################################
create_ca() {
   echo ""
   #echo "-------------------------------------"
   alert "Generating CA ..."
   [ "${DEBUG}" = "true" ] && alert "ALIAS: ${CAALIAS}"
   ${KEYTOOLCMD} -genkeypair -keystore ${CAALIAS}.jks \
           -keypass capass -storepass capass \
           -alias ${CAALIAS} -dname "${DNAME}" \
           -ext bc:c -validity 3650 -keyalg RSA

   [ "${DEBUG}" = "true" ] && echo "" && alert "Export kaazing.support CA certificate in pem format"
   ${KEYTOOLCMD} -keystore ${CAALIAS}.jks -storepass capass \
           -alias ${CAALIAS} -exportcert -rfc > ${CAALIAS}.crt
}

###########################################################
# Create cert for this host
###########################################################
create_host_cert() {
   echo ""
   #echo "-------------------------------------"
   alert "Generating host cert ..."
   [ "${DEBUG}" = "true" ] && alert "KEYSTORE: ${MYALIAS}.jks"
   ${KEYTOOLCMD} -genkeypair -keystore ${MYALIAS}.jks -keypass storepass \
           -storepass storepass -alias ${MYFQDN} -dname "${MYLDAPSPEC}" \
           -keyalg ${KEYALG} -validity 3650

   echo ""
   alert "Generating CSR ..."
   ${KEYTOOLCMD} -keystore ${MYALIAS}.jks -keypass storepass \
           -storepass storepass -certreq -alias ${MYFQDN} > ${MYALIAS}.csr

   echo ""
   alert "Signing cert ..."
   ${KEYTOOLCMD} -keystore ${CAALIAS}.jks -storepass capass -keypass capass \
           -gencert -alias ${CAALIAS} -ext ku:c=dig,keyenc \
           -ext SAN="${MYDNSSPEC}" -rfc < ${MYALIAS}.csr > ${MYALIAS}.crt -validity 1800

   echo ""
   alert "Importing signed certificate ..."
   cat ${CAALIAS}.crt ${MYALIAS}.crt > ca-and-${MYALIAS}.crt
   ${KEYTOOLCMD} -keystore ${MYALIAS}.jks -storepass storepass -importcert \
           -file ca-and-${MYALIAS}.crt -alias ${MYFQDN} -noprompt

   #echo ""

}

###########################################################
# Import CA to truststore
###########################################################
import_ca_to_truststore() {
   echo ""
   #echo "-------------------------------------"
   alert "Adding CA to truststore ..."    # ./import-ca-to-truststore.sh cloudappnetca truststore-temp.db

   # Deleting CA alias
   ${KEYTOOLCMD} -delete -alias ${CAALIAS} -keystore ${TMP_TRUSTSTORE} -storepass changeit -noprompt | head -0
   #alert "ALERT: Above error can be safely ignored."

   # Adding CA as specified alias
   ${KEYTOOLCMD} -importcert -trustcacerts -alias ${CAALIAS} -file ${CAALIAS}.crt -keystore ${TMP_TRUSTSTORE} -storepass changeit -noprompt

   if [ "${DEBUG}" = "true" ]  
   then
      echo ""
      echo "-------------------------------------"
      echo "Checking truststore for ${CAALIAS}"
      ${KEYTOOLCMD} -list -keystore ${TMP_TRUSTSTORE} | grep ${CAALIAS}
      echo You should see an entry for ${CAALIAS}
   fi

  cp ${TMP_TRUSTSTORE} ${TARGETDIR}/truststore.db
}

###########################################################
# Import cert to keystore
###########################################################
import_cert_to_keystore() {
   echo ""
   #echo "-------------------------------------"
   alert "Adding cert to keystore ..." 

   [ "$DEBUG" = "true" ] && echo "Import certificate in ${MYALIAS}.jks into keystore ${TMP_KEYSTORE}"
   ${KEYTOOLCMD} -importkeystore -srckeystore ${MYALIAS}.jks \
           -srcstoretype JKS -srcalias ${MYFQDN} -srcstorepass storepass \
           -destkeystore ${TMP_KEYSTORE} -deststoretype JCEKS -deststorepass ${MYPASSWD} \
           -destalias ${MYFQDN} -destkeypass ${MYPASSWD} -noprompt

   if [ "${DEBUG}" = "true" ]  
   then
      echo ""
      echo "-------------------------------------"
      echo "Dumping keystore ..."
      ${KEYTOOLCMD} -list -keystore ${TMP_KEYSTORE} -storetype JCEKS
   fi
}

###########################################################
# Create pem file
###########################################################
create_pem() {
   echo ""
   #echo "-------------------------------------"
   alert "Creating pem file ..."

   ${KEYTOOLCMD} -importkeystore -srckeystore ${TMP_KEYSTORE} -destkeystore ${MYFQDN}.p12 \
           -srcstoretype JCEKS -deststoretype PKCS12 -srcstorepass ${MYPASSWD} \
           -deststorepass ${MYPASSWD} -srcalias ${MYFQDN} -destalias ${MYFQDN} -noprompt

   openssl pkcs12 -in ${MYFQDN}.p12 -out ${MYFQDN}.pem -passin pass:${MYPASSWD} -passout pass:${MYPASSWD}
   echo ""

   cp ${TMP_KEYSTORE} ${TARGETDIR}/keystore.db
}

###########################################################
# Copy new stores to the conf directory
###########################################################
copy_stores_to_conf() {
   #echo ""
   #echo "-------------------------------------"
   alert "Copying new stores to conf dir ..."

   cp ${TARGETDIR}/keystore.db   ${CONFDIR}/.
   cp ${TARGETDIR}/truststore.db ${CONFDIR}/.

   #echo "-------------------------------------"
}

###########################################################
# Cleanup tmp files
###########################################################
cleanup() {
   #echo ""
   #echo "-------------------------------------"
   [ "${DEBUG}" = "true" ] && alert "Cleaning up ..."
   rm ${TARGETDIR}/*.db
   rm ${TARGETDIR}/*.pw
   rm ${TMPDIR}/*.crt
   rm ${TMPDIR}/*.jks
   rm ${TMPDIR}/*.csr
   rm ${TMPDIR}/*.db
   rm ${TMPDIR}/*.pw
   rm ${TMPDIR}/*.pem
   rm ${TMPDIR}/*.p12
   #echo "-------------------------------------"
}

###########################################################
# Say bye!
###########################################################
bye() {
   echo ""
   echo "-------------------------------------"
   alert "All Done. Have a nice day!"
   echo "-------------------------------------"
}

###########################################################
# Getting the ball rolling
###########################################################
main

###########################################################
## EOF
###########################################################
