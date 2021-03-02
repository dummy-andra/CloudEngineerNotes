##!/usr/bin/env bash
set -e
. ./params.sh



### Create VNet RG
echo "Create RG for Vnet"
echo  $(date) >> deploy-log.yaml
echo  "" >> deploy-log.yaml; echo  "Create RG for Vnet" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
az group create --name $VNET_RG --location $VNET_LOCATION --tags env=lab >> deploy-log.yaml 2>&1

### Create VNet
echo "Create Vnet"
echo  "" >> deploy-log.yaml; echo  "Create Vnet" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
az network vnet create -g $VNET_RG -n $VNET_NAME --address-prefix $VNET_PREFIX >> deploy-log.yaml 2>&1

### Create Subnet for APP Gateway
echo "Create SubNet for APP GTW"
echo  "" >> deploy-log.yaml; echo  "Create SubNet for APP GTW" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
az network vnet subnet create -g $VNET_RG --vnet-name $VNET_NAME -n $VNET_SNET_APPGTW_NAME --address-prefixes $VNET_SNET_APPGTW_PREFIX >> deploy-log.yaml 2>&1

### Create Subnet for AKS cluster
echo "Create SubNet for AKS Cluster"
echo  "" >> deploy-log.yaml; echo  "Create SubNet for AKS Cluster" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
az network vnet subnet create -g $VNET_RG --vnet-name $VNET_NAME -n $VNET_SNET_AKS_NAME --address-prefixes $VNET_SNET_AKSPREFIX >> deploy-log.yaml 2>&1

### Get the id of the Subnet for AKS
echo "Get the Subnet for AKS ID" 
echo  "" >> deploy-log.yaml; echo  "Get the Subnet for AKS ID" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
AKS_SNET_ID=$(az network vnet subnet show -g $VNET_RG --vnet-name $VNET_NAME --name $VNET_SNET_AKS_NAME --query id -o tsv) 
echo $AKS_SNET_ID >> deploy-log.yaml 2>&1

### create aks cluster
echo "Creating AKS Cluster RG"

echo  "" >> deploy-log.yaml; echo  "Creating AKS Cluster RG" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
az group create --name $RG_NAME --location $LOCATION --tags env=lab >> deploy-log.yaml 2>&1

# Create azure container register
echo "Create azure container register"
echo  "" >> deploy-log.yaml; echo  "Create azure container register" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
az acr create -n $ACR_Name -g $RG_NAME --sku standard >> deploy-log.yaml 2>&1


# Create a service principal without a default assignment.
echo "Create a service principal"
echo  "" >> deploy-log.yaml; echo "Create a service principal see output in sp-credentials file" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
echo  $(date) >> sp-credentials.yaml
az ad sp create-for-rbac \
    --name $AKS_SP_NAME \
    --skip-assignment >> sp-credentials.yaml 2>&1

# Retrieve Service principal APPID and Client Secret
AKS_SP_APP_ID=$(az ad app list --display-name $AKS_SP_NAME --query "[].appId" -o tsv)
AKS_SP_SECRET=$(az ad sp credential reset --name $AKS_SP_NAME --query "password" -o tsv)


echo "Creating AKS Cluster"
echo  "" >> deploy-log.yaml; echo "Creating AKS Cluster" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
az aks create --resource-group $RG_NAME --name $CLUSTER_NAME \
    --service-principal $AKS_SP_APP_ID \
    --client-secret $AKS_SP_SECRET \
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
    --debug >> deploy-log.yaml 2>&1



### Get Credentials
echo ""
echo "Getting Cluster Credentials"
echo  "" >> deploy-log.yaml; echo "Getting Cluster Credentials" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME

## Connect ACR with AKS cluster
echo ""
echo "Connect ACR with AKS cluster"
echo  "" >> deploy-log.yaml; echo "Connect ACR with AKS cluster see output in aks_id file" >> deploy-log.yaml; echo  "" >> deploy-log.yaml
# Get AKS Client Id and AKS Id
CLIENT_ID=$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
ACR_ID=$(az acr show --name $ACR_Name --resource-group $RG_NAME --query "id" --output tsv)
echo  $(date) >> aks_id.yaml
echo "CLIENT_ID is " $CLIENT_ID >> aks_id.yaml 2>&1
echo "ACR_ID is " $ACR_ID >> aks_id.yaml 2>&1


# Give AKS access to ACR
echo ""
echo "Give AKS access to ACR"
echo  "" >> deploy-log.yaml; echo "Give AKS access to ACR" >> deploy-log.yaml; echo  "" >> deploy-log.yaml 2>&1
echo  $(date) >> aks_id.yaml
az role assignment create --assignee $CLIENT_ID --role acrpull --scope $ACR_ID >> aks_id.yaml 2>&1