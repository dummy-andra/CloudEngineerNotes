# Simple private cluster

```
az group create --name test-gr --location eastus

az network vnet create \
  --name test-vnet \
  --resource-group test-gr \
  --subnet-name default
 
az network vnet subnet create \
  --address-prefixes 10.0.4.0/22\
  --name aks-subnet \
  --resource-group test-gr \
  --vnet-name test-vnet



az network vnet subnet list --resource-group test-gr --vnet-name test-vnet


az aks create \
    --resource-group test-gr \
    --name private-aks \
    --load-balancer-sku standard \
    --enable-private-cluster \
    --network-plugin azure \
    --vnet-subnet-id /subscriptions/<your-subs>/resourceGroups/test-storage /providers/Microsoft.Network/virtualNetworks/test-storage-vnet/subnets/aks-subnet \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24



For testing:

A private cluster can be accessed only from a VM inside the VNET

I decided to create a special subnet for the VM to keep VM and aks subnets, separated

az network vnet subnet create \
  --address-prefixes 10.0.2.0/24\
  --name devops-subnet \
  --resource-group test-gr \
  --vnet-name test-vnet

az vm create \
  --resource-group test-rg  \
  --name devopsagent \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys \
  --subnet devops-subnet \
  --vnet-name test-vnet


Connect and prepare the vm
ssh azureuser@publicIpAddress
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo az aks install-cli

```
