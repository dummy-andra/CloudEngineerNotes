##!/usr/bin/env bash
set -e
. ./params.sh

#Create a resource group
az group create --name $RESOURCEGROUP --location $LOCATION

#Create the virtual network
az network vnet create \
  -g $RESOURCEGROUP \
  -n $AROVNET \
  --address-prefixes 10.0.0.0/8

#Add two empty subnets to your virtual network
az network vnet subnet create \
  -g $RESOURCEGROUP \
  --vnet-name $AROVNET \
  -n $CLUSTER-master \
  --address-prefixes 10.10.1.0/24 \
  --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet create \
  -g $RESOURCEGROUP \
  --vnet-name $AROVNET \
  -n $CLUSTER-worker \
  --address-prefixes 10.20.1.0/24 \
  --service-endpoints Microsoft.ContainerRegistry

 # Disable network policies for Private Link Service on your virtual network and subnets. 
 #This is a requirement for the ARO service to access and manage the cluster. 

 az network vnet subnet update \
  -g $RESOURCEGROUP \
  --vnet-name $AROVNET \
  -n $CLUSTER-master \
  --disable-private-link-service-network-policies true

#Create a Firewall Subnet
az network vnet subnet create \
    -g $RESOURCEGROUP \
    --vnet-name $AROVNET \
    -n "AzureFirewallSubnet" \
    --address-prefixes 10.100.1.0/26

#Create a jump-host VM

#Create a jump-subnet
  az network vnet subnet create \
    -g $RESOURCEGROUP \
    --vnet-name $AROVNET \
    -n $JUMPSUBNET \
    --address-prefixes 10.30.1.0/24 \
    --service-endpoints Microsoft.ContainerRegistry

#Create a jump-host VM


az vm create --name ubuntu-jump \
             --resource-group $RESOURCEGROUP \
             --ssh-key-values ~/.ssh/egress_id_rsa.pub \
             --admin-username $VMUSERNAME \
             --image UbuntuLTS \
             --subnet $JUMPSUBNET \
             --public-ip-address jumphost-ip \
             --vnet-name $AROVNET 


# Deploy ARO Cluster

az aro create \
  -g $RESOURCEGROUP \
  -n $CLUSTER \
  --vnet $AROVNET \
  --master-subnet $CLUSTER-master \
  --worker-subnet $CLUSTER-worker \
  --apiserver-visibility Private \
  --ingress-visibility Private \
  --pull-secret @pull-secret.txt


#Get the cluster credentials
ARO_PASSWORD=$(az aro list-credentials -n $CLUSTER -g $RESOURCEGROUP -o json | jq -r '.kubeadminPassword')
ARO_USERNAME=$(az aro list-credentials -n $CLUSTER -g $RESOURCEGROUP -o json | jq -r '.kubeadminUsername')

#Get an API server endpoint:
ARO_URL=$(az aro show -n $CLUSTER -g $RESOURCEGROUP -o json | jq -r '.apiserverProfile.url')

echo "ARO_PASSWORD="$ARO_PASSWORD >> credentials.sh
echo "ARO_USERNAME="$ARO_USERNAME >> credentials.sh
echo "ARO_URL="$ARO_URL >> credentials.sh

#Create an Azure Firewall

#Create a public IP Address
az network public-ip create -g $RESOURCEGROUP -n fw-ip --sku "Standard" --location $LOCATION

#Update install Azure Firewall extension
az extension add -n azure-firewall
az extension update -n azure-firewall

#Create Azure Firewall and configure IP Config
az network firewall create -g $RESOURCEGROUP -n aro-private -l $LOCATION
az network firewall ip-config create -g $RESOURCEGROUP -f aro-private -n fw-config --public-ip-address fw-ip --vnet-name $AROVNET

#Capture Azure Firewall IPs for a later use
FWPUBLIC_IP=$(az network public-ip show -g $RESOURCEGROUP -n fw-ip --query "ipAddress" -o tsv)
FWPRIVATE_IP=$(az network firewall show -g $RESOURCEGROUP -n aro-private --query "ipConfigurations[0].privateIpAddress" -o tsv)

echo $FWPUBLIC_IP
echo $FWPRIVATE_IP

#Create a UDR and Routing Table for Azure Firewall
az network route-table create -g $RESOURCEGROUP --name aro-udr

az network route-table route create -g $RESOURCEGROUP --name aro-udr --route-table-name aro-udr --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FWPRIVATE_IP

#Add app rules for Arure Firewall

az network firewall application-rule create -g $RESOURCEGROUP -f aro-private \
    --collection-name 'ARO' \
    --action allow \
    --priority 100 \
    -n 'required' \
    --source-addresses '*' \
    --protocols 'http=80' 'https=443' \
    --target-fqdns 'registry.redhat.io' '*.quay.io' 'sso.redhat.com' 'management.azure.com' 'mirror.openshift.com' 'api.openshift.com' 'quay.io' '*.blob.core.windows.net' 'gcs.prod.monitoring.core.windows.net' 'registry.access.redhat.com' 'login.microsoftonline.com' '*.servicebus.windows.net' '*.table.core.windows.net' 'grafana.com'


#Rules for Docker images:

az network firewall application-rule create -g $RESOURCEGROUP -f aro-private \
    --collection-name 'Docker' \
    --action allow \
    --priority 200 \
    -n 'docker' \
    --source-addresses '*' \
    --protocols 'http=80' 'https=443' \
    --target-fqdns '*cloudflare.docker.com' '*registry-1.docker.io' 'apt.dockerproject.org' 'auth.docker.io'

#Associate ARO Subnets to FW
az network vnet subnet update -g $RESOURCEGROUP --vnet-name $AROVNET --name $CLUSTER-master --route-table aro-udr
az network vnet subnet update -g $RESOURCEGROUP --vnet-name $AROVNET --name $CLUSTER-worker --route-table aro-udr



