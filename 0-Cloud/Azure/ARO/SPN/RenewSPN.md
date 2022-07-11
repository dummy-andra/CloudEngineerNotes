
## Important: Once command is executed it might take up to 30 min for this to take effect. 


az az show --name $AKS_CLUSTER_NAME --resource-group $AKS_CLUSTER_RESOURCE_GROUP --query servicePrincipalProfile.clientId -o tsv

az ad app credential list --id $AKS_SP_APP_ID

# Renew the SPN
```
ARO_SP_APP_ID=$(az ad app list --display-name $SP_NAME --query "[].appId" -o tsv)
ARO_SP_SECRET=$(az ad sp credential reset --name $SP_NAME --query "password" -o tsv)

or:
az ad sp credential reset --name [id|name] -p newSecretPassword --years 2 

or 

az ad sp credential reset --name [id|name] -p newSecretPassword --end-date '2299-12-31'
```



## Update ARO Cluster with the new SP 


# For ARO 4

Update the ARO with the new SPN using the json patch



Create a JSON file "ssp.json" with the following contents, where AZURE_SUBSCRIPTION_ID, RESOURCEGROUP, CLUSTER and LOCATION are replaced with cluster parameters, and  you need to find in the cluster json how the subnet is looking and the sintax

```
cat <<EOF > ssp.json
{
    "id": "/subscriptions/xxxxxxxxxxxxx/resourceGroups/aro-public-gr/providers/Microsoft.RedHatOpenShift/OpenShiftClusters/aro-public-cluster",
    "name": "aro-public-cluster",
    "type": "Microsoft.RedHatOpenShift/openShiftClusters",
    "location": "eastus",
    "properties": {
        "servicePrincipalProfile": {
            "clientId": "xxxxxxx",
            "clientSecret": "xxxxx"
        }
    }
}
EOF
```

After that run the following command to send a raw API request

az rest --method patch --url https://management.azure.com/subscriptions/xxxxxxxxxxx/resourceGroups/aro-public-gr/providers/Microsoft.RedHatOpenShift/OpenShiftClusters/aro-public-cluster?api-version=2020-04-30 --body @ssp.json




# For ARO 3.11 




az rest --method PUT -u https://management.azure.com/subscriptions/{subscription}/resourceGroups/n{resouce_group}/providers/Microsoft.ContainerService/openShiftManagedClusters/{cluster_name}?api-version=2019-09-30-preview --body @creds.json --debug



Where: @creds.json 

```
cat <<EOF > creds.json
{
    "id": "/subscriptions/{subscription}/resourcegroups/{resource_group}/providers/Microsoft.ContainerService/openshiftmanagedClusters/{cluster_name}",
    "name": "{cluster_name}",
    "type": "Microsoft.ContainerService/OpenShiftManagedClusters",
    "location": "{location}",
    "tags": {},
    "properties": {
     "authProfile": {
      "identityProviders": [
       {
        "name": "Azure AD",
        "provider": {
         "kind": "AADIdentityProvider",
         "clientId": "{client_id}",
         "tenantId": "{tenant_id}",
         "secret": "{secret}",
         "customerAdminGroupId": "{customerAdminGroupId}"
        }
       }
      ]
     }
   }
}
EOF
```

Where populated values can be found by executing `az openshift show`