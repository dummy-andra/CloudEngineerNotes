##!/usr/bin/env bash
set -e
. ./params.sh



### Create VNet RG
echo "Create RG for Vnet"
az group create --name $VNET_RG --location $VNET_LOCATION --tags env=lab > /dev/null 2>&1

### Create VNet
echo "Create Vnet"
az network vnet create -g $VNET_RG -n $VNET_NAME --address-prefix $VNET_PREFIX > /dev/null 2>&1

### Create Subnet for APP Gateway
echo "Create SubNet for APP GTW"
az network vnet subnet create -g $VNET_RG --vnet-name $VNET_NAME -n $VNET_SNET_APPGTW_NAME --address-prefixes $VNET_SNET_APPGTW_PREFIX > /dev/null 2>&1

### Create Subnet for AKS cluster
echo "Create SubNet for AKS Cluster"
az network vnet subnet create -g $VNET_RG --vnet-name $VNET_NAME -n $VNET_SNET_AKS_NAME --address-prefixes $VNET_SNET_AKSPREFIX > /dev/null 2>&1

### Get the id of the Subnet for AKS
echo "Get the Subnet for AKS ID" 
AKS_SNET_ID=$(az network vnet subnet show -g $VNET_RG --vnet-name $VNET_NAME --name $VNET_SNET_AKS_NAME --query id -o tsv)

### create aks cluster
echo "Creating AKS Cluster RG"
echo $RG_NAME
az group create --name $RG_NAME --location $LOCATION --tags env=lab > /dev/null 2>&1

# Create azure container register
az acr create -n $ACR_Name -g $RG_NAME --sku standard 

# Create a service principal without a default assignment.
$SP=$(az ad sp create-for-rbac --name spHelloWorld --skip-assignment)
$SP_appId=$(echo $SP | tr -s "," "\n" | awk '{if (NR==1) {print$3}}')
$SP_PASS=$(echo $SP | tr -s "," "\n" | awk '{if (NR==4) {print$2}}' )

echo "Creating AKS Cluster"
az aks create --resource-group $RG_NAME --name $CLUSTER_NAME \
--service-principal $SP_appId \
--client-secret $SP_PASS \
--node-count $NODE_COUNT \
--node-vm-size Standard_DS2_v2 \
--location $LOCATION \
--load-balancer-sku standard \
--vm-set-type $VMSETTYPE \
--kubernetes-version $VERSION \
--enable-addons monitoring \
--network-plugin kubenet \
--no-ssh-key \
--vnet-subnet-id $AKS_SNET_ID  \
--dns-service-ip $DNS_SRV \
--service-cidr $SRV_CIDR \
--pod-cidr $POD_CIDR \
--docker-bridge-address $DOCKER_BRIDGE_ADDRESS \
--debug > /dev/null 2>&1

## Connect ACR with AKS cluster

# Get AKS Client Id and AKS Id
$CLIENT_ID=$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
$ACR_ID=$(az acr show --name $ACR_Name --resource-group $RG_NAME --query "id" --output tsv)

# Give AKS access to ACR
az role assignment create --assignee $CLIENT_ID --role acrpull --scope $ACR_ID

### Get Credentialsi
echo ""
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME