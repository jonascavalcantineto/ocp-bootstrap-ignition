#!/bin/bash

COMPANY=$1
PATH_CERTS=$2
CERT=$3
CERT_KEY=$4

if [[ $# -eq 2 ]] ; then
    echo "Using: $0 <comapny-name> <path-certificates> <cartificate-name> <key-cartificate-name>"
    exit 1
fi

echo "Create a ConfigMap that includes the certificate authority used to signed the new certificate"
oc create configmap custom-ca \
     --from-file=ca-bundle.crt=${PATH_CERTS}/${CERT}.pem> \
     -n openshift-config

echo "Update the cluster-wide proxy configuration with the newly created ConfigMap"
oc create secret tls apps-${COMPANY}-cert \
     --cert=${PATH_CERTS}/${CERT}.pem \
     --key=${PATH_CERTS}/${CERT_KEY}.key> \
     -n openshift-ingress

echo "Update the Ingress Controller configuration with the newly created secret:"
oc patch ingresscontroller.operator default \
     --type=merge -p \
     '{"spec":{"defaultCertificate": {"name": "apps-${COMPANY}-cert"}}}' \
     -n openshift-ingress-operator