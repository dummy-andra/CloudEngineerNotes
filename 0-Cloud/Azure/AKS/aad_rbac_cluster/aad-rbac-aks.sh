##!/usr/bin/env bash
set -e
. ./params.sh


### Create resource group
az group create --name $RG_NAME --location $LOCATION 




echo "Creating AKS Cluster"

az aks create --resource-group $RG_NAME --name $CLUSTER_NAME \
    --node-count $NODE_COUNT \
    --node-vm-size Standard_DS2_v2 \
    --location $LOCATION \
    --load-balancer-sku standard \
    --vm-set-type $VMSETTYPE \
    --kubernetes-version $VERSION \
    --network-plugin kubenet \
    --no-ssh-key \
    --enable-aad \
    --enable-azure-rbac \
    --debug 



### Get Credentials
echo ""
echo "Getting Cluster Credentials"

az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME