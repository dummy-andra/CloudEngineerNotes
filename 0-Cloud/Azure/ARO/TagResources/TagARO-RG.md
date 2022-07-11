# There is a method on how to add tags, you need to use an SPN (either at aro creation, either you assigned after as a contributor).



> See the example below:


**If you created an ARO with SPN**

```
# Login with the SPN

az login --service-principal --username $AROSPID --password $TaggingSecret --tenant $TENANT_ID --allow-no-subscriptions

az account set --subscription <Subscription-ID>



# Update the RG with the tag (here I updated the ARO node RG - the group that has the nodes in it as an example)

az group update --resource-group aro-opt3q6gh --set tags.CostCenter='{"Dept":"IT","Environment":"Test"}'

az tag list --resource-id /subscriptions/xxxxxxxxxxxxxxxxxx/resourceGroups/aro-opt3q6gh
```
 

![image](https://user-images.githubusercontent.com/37038210/121653666-9c8f8c80-caa5-11eb-963f-66ea74ca5df3.png)



#  **If your ARO cluster was created without an SPN**
</br>


**- Create separately an SPN** 
```
# Create a service principal without a default assignment.
echo "Create a service principal"

az ad sp create-for-rbac \
    --name <SPN-NAME> \
    --skip-assignment >> sp-credentials.yaml 2>&1



# Retrieve Service principal APPID and Client Secret
ARO_SP_APP_ID=$(az ad app list --display-name <SPN-NAME> --query "[].appId" -o tsv)
ARO_SP_SECRET=$(az ad sp credential reset --name <SPN-NAME> --query "password" -o tsv)
```

</br>

**- Attach the newly created SPN to your ARO groups  with contributor role**
</br>

`az role assignment create --assignee <appId> --scope <resourceScope> --role Contributor`
</br>


> The --scope for a resource needs to be a full resource ID, such as 
```
/subscriptions/<guid>/resourceGroups/myResourceGroup or /subscriptions/<guid>/resourceGroups/myResourceGroupVnet/providers/Microsoft.Network/virtualNetworks/myVnet
```

</br>


**- Update the ARO with the new SPN using the json patch**




</br>

Create a JSON file "ssp.json" with the following contents, where AZURE_SUBSCRIPTION_ID, RESOURCEGROUP, CLUSTER, and LOCATION are replaced with cluster parameters, and  you need to find in the cluster json how the subnet is looking and the syntax

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
</br>


After that run the following command to send a raw API request

`az rest --method patch --url https://management.azure.com/subscriptions/xxxxxxxxxxx/resourceGroups/aro-public-gr/providers/Microsoft.RedHatOpenShift/OpenShiftClusters/aro-public-cluster?api-version=2020-04-30 --body @ssp.json`

</br>

**- Log in with the SPN and add tags (like presented above)**




# Or use this method

```
ADMIN="kubeadmin"
ADMINPW="X"
APISERVER="https://api.foo.region.aroapp.io:6443"
TAGS="tags.joy=sadness tags.bing=bong tags.inside=out"

oc login $APISERVER -u $ADMIN -p $ADMINPW
SPAPPID="$(oc get secret azure-credentials -n kube-system -o json | jq -r .data.azure_client_id | base64 --decode)"
SPSECRET="$(oc get secret azure-credentials -n kube-system -o json | jq -r .data.azure_client_secret | base64 --decode)"
SPTENANT="$(oc get secret azure-credentials -n kube-system -o json | jq -r .data.azure_tenant_id | base64 --decode)"
CLUSTERRG="$(oc get secret azure-credentials -n kube-system -o json | jq -r .data.azure_resourcegroup |base64 --decode)"
az login --service-principal -u $SPAPPID -p $SPSECRET -t $SPTENANT
az group update -n $CLUSTERRG --set $TAGS -o jsonc
az logout
```

