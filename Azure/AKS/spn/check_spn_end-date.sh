##!/usr/bin/env bash
set -e
. ./params.sh




# Retrieve Service principal APPID and Client Secret
AKS_SP_APP_ID=$(az ad app list --display-name $AKS_SP_NAME --query "[].appId" -o tsv)


# Display information about SPN using the cliend id
SP=$(az ad app credential list --id  $AKS_SP_APP_ID)

# Extract the end date
endDate=$(echo $SP |  tr -s "," "\n" | awk '{if (NR==3) {print$2}}' | tr -d \")

echo "End date is " + $endDate


# Format date for condition
now=$(date  +%Y%m%d%H%M%S)
expiration_date=$(date -d  $endDate  +%Y%m%d%H%M%S)



# Compare today with expiration date
if [ $now -ge $expiration_date ];
then
    # IF expiration date in the next 30 days rest password
    sp_id=$(az aks show -g $resource_group -n $cluster_name --query servicePrincipalProfile.clientId -o tsv)
    service_principle_secret=$(az ad sp credential reset --name $sp_id --end-date $(date -d "+ 90 days"  +%Y-%m-%d) --query password -o tsv)

    # Update cluster with new password
    az aks update-credentials \
    --resource-group $resource_group \
    --name $cluster_name \
    --reset-service-principal \
    --service-principal $sp_id \
    --client-secret $service_principle_secret
fi