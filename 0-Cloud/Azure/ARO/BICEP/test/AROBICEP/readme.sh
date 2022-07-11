##!/usr/bin/env bash
set -e
. ./params.sh 

echo "$(date) - Deploying OpenShift cluster"



## Stage - Deploy Service Principle for OpenShift Cluster

MESSAGE="Creating OpenShift Service Principle"
echo $MESSAGE

APP_ID="xxxx"
SERVICE_PRINCIPAL_NAME=$CLUSTER_NAME-SP
RESOURCE_GROUP_ID=$(az group show --resource-group $RESOURCE_GROUP_NAME --query id --output tsv)

SCOPE=$RESOURCE_GROUP_ID
ROLE="Owner"

az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role $ROLE --scopes $SCOPE > aro-sp.json
clientId=$(jq -r .appId <aro-sp.json)
clientSecret=$(jq -r .password <aro-sp.json)
pullSecret=$(cat pull-secret.txt)


##  Assign the OpenShift Resource Provider permissions to the RG as well.
##  More restrictive, this can be done at the VNET level with only network contributer
az role assignment create --role $ROLE --assignee $APP_ID --scope $SCOPE



az deployment sub create \
    -f main.bicep \
    -l australiaeast \
    --parameters pullSecret=$pullSecret clientId=$clientId clientSecret=$clientSecret \
    --debug






## Stage - Deploy Resource Group for OpenShift Cluster

MESSAGE="Creating OpenShift Resource Group"
log $MESSAGE

DEPLOYMENT_NAME="deploy-openshift-rg"

TEMPLATE_FILE="resourceGroups.bicep"
#PARAMETERS_FILE="resourceGroups.paramters.json"

az deployment sub create \
    --name $DEPLOYMENT_NAME \
    --location $RESOURCE_GROUP_LOACTION \
    --template-file $TEMPLATE_FILE \
    --parameters resourceGroupName=$RESOURCE_GROUP_NAME \
    --parameters resourceGroupLocation=$RESOURCE_GROUP_LOACTION \
    --verbose
    

MESSAGE="Created OpenShift Resource Group"
log $MESSAGE


## Stage - Deploy Virtual Network for OpenShift Cluster

MESSAGE="Creating OpenShift Virtual Network"
log $MESSAGE

DEPLOYMENT_NAME="deploy-openshift-vnet"

TEMPLATE_FILE="vnet.bicep"


az deployment group create \
    --name $DEPLOYMENT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --template-file $TEMPLATE_FILE \
    --verbose

MESSAGE="Created OpenShift Virtual Network"
log $MESSAGE


## Stage - Deploy Service Principle for OpenShift Cluster

MESSAGE="Creating OpenShift Service Principle"
log $MESSAGE

APP_ID="f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875"
SERVICE_PRINCIPAL_NAME=$CLUSTER_NAME-SP
RESOURCE_GROUP_ID=$(az group show --resource-group $RESOURCE_GROUP_NAME --query id --output tsv)

SCOPE=$RESOURCE_GROUP_ID
ROLE="Owner"

az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role $ROLE --scopes $SCOPE > aro-sp.json
clientId=$(jq -r .appId <aro-sp.json)
clientSecret=$(jq -r .password <aro-sp.json)
pullSecret=$(cat pull-secret.txt)
#RESULT=`az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role $ROLE --scopes $SCOPE`
#echo $RESULT

##  Assign the OpenShift Resource Provider permissions to the RG as well.
##  More restrictive, this can be done at the VNET level with only network contributer
az role assignment create --role $ROLE --assignee $APP_ID --scope $SCOPE


MESSAGE="Created OpenShift Service Principle"
log $MESSAGE


## Stage - Deploy the OpenShift Cluster

MESSAGE="Deploying OpenShift Cluster"
log $MESSAGE

DEPLOYMENT_NAME="deploy-openshift-cluster"

TEMPLATE_FILE="aro.bicep"
PARAMETERS_FILE="../bicep/openShiftClusters.paramters.json"

az deployment group create \
    --name $DEPLOYMENT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --template-file $TEMPLATE_FILE \
    --parameters pullSecret=$pullSecret clientId=$clientId clientSecret=$clientSecret \
    --verbose

MESSAGE="Deployment of OpenShift Cluster complete"
log $MESSAGE



