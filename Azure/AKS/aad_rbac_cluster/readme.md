> If AzureRBAC is enabled, then built-in roles will authenticate and get authorized to fetch cluster resources

# Create an AKS-managed Azure AD cluster

`az aks create -g MyResourceGroup -n MyManagedCluster --enable-aad --enable-azure-rbac`

Article

[Manage Azure RBAC in Kubernetes From Azure - Azure Kubernetes Service | Microsoft Docs](https://docs.microsoft.com/en-us/azure/aks/manage-azure-rbac)
