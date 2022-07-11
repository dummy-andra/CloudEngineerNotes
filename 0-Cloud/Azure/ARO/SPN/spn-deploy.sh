##!/usr/bin/env bash
set -e
. ./params.sh



# Create Resource Group
az group create \
  --name $RESOURCEGROUP \
  --location $LOCATION

# Create a virtual network
az network vnet create \
   --resource-group $RESOURCEGROUP \
   --name aro-vnet \
   --address-prefixes 10.0.0.0/22

# Add an empty subnet for the master nodes
az network vnet subnet create \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --name master-subnet \
  --address-prefixes 10.0.0.0/23 \
  --service-endpoints Microsoft.ContainerRegistry

# Add an empty subnet for the worker nodes
az network vnet subnet create \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --name worker-subnet \
  --address-prefixes 10.0.2.0/23 \
  --service-endpoints Microsoft.ContainerRegistry

# Disable subnet private endpoint policies on the master subnet. This is required for the service to be able to connect to and manage the cluster.
az network vnet subnet update \
  --name master-subnet \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --disable-private-link-service-network-policies true


# Create a service principal without a default assignment.
echo "Create a service principal"

# az ad sp create-for-rbac \
#     --name $SPN \
#     --skip-assignment >> sp-credentials.yaml 2>&1



# # Retrieve Service principal APPID and Client Secret
# ARO_SP_APP_ID=$(az ad app list --display-name $SPN --query "[].appId" -o tsv)
# ARO_SP_SECRET=$(az ad sp credential reset --name $SPN --query "password" -o tsv)



    # --service-principal $ARO_SP_APP_ID 
    # --client-secret $ARO_SP_SECRET 

CLUSTER_NAME=aro-spn-group-domo
SERVICE_PRINCIPAL_NAME=$CLUSTER_NAME-SP 
az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --skip-assignment > aro-sp.json 
clientId=$(jq -r .appId <aro-sp.json) 
clientSecret=$(jq -r .password <aro-sp.json) 
pullSecret=$(cat pull-secret.txt) 


# Create the cluster
az aro create \
    --resource-group $RESOURCEGROUP \
    --name $CLUSTER \
    --vnet aro-vnet \
    --master-subnet master-subnet \
    --worker-subnet worker-subnet \
    --client-id $clientId \
    --client-secret $clientSecret \
    --pull-secret @pull-secret.txt 


# In case of update
# az aro update \
#     --name aro-spn-cluster-demo \
#     --resource-group aro-spn-group-domo \
#     --client-id xxx \
#     --client-secret xxx \
#     --debug



# Connect to the cluster
# az aro list-credentials \
#   --name $CLUSTER \
#   --resource-group $RESOURCEGROUP


ARO_Credentials=$(az aro list-credentials --name $CLUSTER --resource-group $RESOURCEGROUP )
pass=$(echo $ARO_Credentials | tr -s "," "\n" | tr -d \" | awk '{if (NR==1) {print$3}}' )
user=$(echo $ARO_Credentials | tr -s "," "\n" | tr -d \"| awk '{if (NR==2) {print$2}}' )

# Find the cluster console URL by running the following command
az aro show \
    --name $CLUSTER \
    --resource-group $RESOURCEGROUP \
    --query "consoleProfile.url" -o tsv
    


# Connect using the OpenShift CLI
apiServer=$(az aro show -g $RESOURCEGROUP -n $CLUSTER --query apiserverProfile.url -o tsv)



echo $pass >> credentials.yaml
echo $user >> credentials.yaml
echo $apiServer >> credentials.yaml

oc login $apiServer -u $user -p $pass