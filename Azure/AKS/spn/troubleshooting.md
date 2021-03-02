# Pods could not be deployed

 
### Check SPN expiration date

 ```
SP_ID=$(az aks show --resource-group myResourceGroup --name myAKSCluster --query servicePrincipalProfile.clientId -o tsv)
az ad sp credential list --id $SP_ID --query "[].endDate" -o tsv
```

> If you see a message that your SPN will exire in 200years or more that means that your SPN it's already expired.
The SPN is set to expire if Cluster Birth Date was > 1 year ago 

 
 ### Reset the existing service principal credential 

```
SP_ID=$(az aks show --resource-group myResourceGroup --name myAKSCluster   --query servicePrincipalProfile.clientId -o tsv) 
SP_SECRET=$(az ad sp credential reset --name $SP_ID --query password -o tsv) 
```
  

### Update AKS cluster with new service principal credentials 

```
az aks update-credentials \ 

    --resource-group myResourceGroup \ 

    --name myAKSCluster \ 

    --reset-service-principal \ 

    --service-principal $SP_ID \ 

    --client-secret $SP_SECRET 
```