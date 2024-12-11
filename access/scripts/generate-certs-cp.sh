#!/bin/bash
set -e

# Set variables
CERT_DIR="./certs"
USERS=("port-forward-user" "deploy-app-user")
DAYS_VALID=2

# Create directory for certificates
mkdir -p $CERT_DIR
mkdir -p ${HOME}/.kube/wordpress/

# Loop through users and generate certificates
for USER in "${USERS[@]}"; do
    cp ${HOME}/.kube/config ${HOME}/.kube/wordpress/config-$USER
    export KUBECONFIG="${HOME}/.kube/wordpress/config-$USER"
    echo ">  Using kubeconfig: "${HOME}/.kube/wordpress/config-$USER""

    echo ">  Generating key for $USER"
    openssl genrsa -out $CERT_DIR/$USER.key 2084

    echo ">  Generating certificate signing request (CSR)"
    openssl req -new \
        -key $CERT_DIR/$USER.key \
        -subj "/CN=$USER" \
        -out $CERT_DIR/$USER.csr

    echo ">  Generating certificate for $USER"       
    sudo openssl x509 -req \
        -CA /etc/kubernetes/pki/ca.crt \
        -CAkey /etc/kubernetes/pki/ca.key \
        -in $CERT_DIR/$USER.csr \
        -out $CERT_DIR/$USER.crt \
        -days 2 -set_serial 1234

    echo ">  Adding $USER credentials to kubeconfig"
    kubectl config set-credentials $USER \
        --embed-certs \
        --client-key=$CERT_DIR/$USER.key \
        --client-certificate=$CERT_DIR/$USER.crt

    echo ">  Setting context to $USER@kubernetes"
    kubectl config set-context $USER@kubernetes \
        --user=$USER \
        --cluster=kubernetes \
        --namespace=wordpress
    
    echo ">  Switching to $USER@kubernetes context"
    kubectl config use-context $USER@kubernetes

    echo ">  Remove the kubernetes-admin from the kubeconfig file"
    kubectl config delete-user kubernetes-admin
    kubectl config delete-context kubernetes-admin@kubernetes

    echo ">  Users and context:"
    kubectl config get-users
    kubectl config get-contexts
    
    echo ""
done
