## ACR
ACR_Name="acrHelloWorldStudents"

## SP
AKS_SP_NAME="spHW"

## AKS Cluster
LOCATION="eastus"
RG_NAME="rg-aks-HelloWorld"
CLUSTER_NAME="aks"
NODE_SIZE="Standard_DS2_v2"
NODE_COUNT="3"
NODE_DISK_SIZE="35"
VERSION="1.17.11"
CNI_PLUGIN="kubenet"
VMSETTYPE="VirtualMachineScaleSets"
SRV_CIDR="10.3.0.0/16"
DNS_SRV="10.3.1.1"
POD_CIDR="10.244.0.0/16"
DOCKER_BRIDGE_ADDRESS="172.17.0.1/16"

## VNET
VNET_RG="myResourceGroup"
VNET_LOCATION="eastus"
VNET_NAME="MyVnet"
VNET_PREFIX="10.0.0.0/8"
VNET_SNET_APPGTW_NAME="MySubnetAGTW"
VNET_SNET_APPGTW_PREFIX="10.1.0.0/16"
VNET_SNET_AKS_NAME="MySubnetAKS"
VNET_SNET_AKSPREFIX="10.2.0.0/16"