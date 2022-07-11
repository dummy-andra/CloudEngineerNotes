# Create an AKS-managed Azure AD cluster
az aks create -g AndraResourceGroup -n rbacManagedCluster2 --enable-aad --enable-azure-rbac
# Get your AKS Resource ID
AKS_ID=$(az aks show -g AndraResourceGroup -n rbacManagedCluster --query id -o tsv)
az role assignment create --role "Azure Kubernetes Service RBAC Admin" --assignee <AAD-ENTITY-ID> --scope $AKS_ID
az role assignment create --role "Azure Kubernetes Service RBAC Writer" --assignee <AAD-ENTITY-ID> --scope $AKS_ID
az role assignment create --role "Azure Kubernetes Service Cluster User Role" --assignee <AAD-ENTITY-ID> --scope $AKS_ID

# where <AAD-ENTITY-ID> could be a username (for example, user@contoso.com) or even the ClientID of a service principal.

# AAD-ENTITY-ID I used the User number from the error output
az role assignment create --role "Azure Kubernetes Service RBAC Admin" --assignee 993a6a4f-a850-4738-95be-8c05803eb92e --scope $AKS_ID
az role assignment create --role "Azure Kubernetes Service RBAC Writer" --assignee 993a6a4f-a850-4738-95be-8c05803eb92e --scope $AKS_ID
az role assignment create --role "Azure Kubernetes Service Cluster User Role" --assignee 993a6a4f-a850-4738-95be-8c05803eb92e --scope $AKS_ID



# Create an AKS-managed Azure AD cluster
az aks create -g AndraResourceGroup -n ADManagedCluster --enable-aad

# Create AD group
APPDEV_ID=$(az ad group create --display-name demo --mail-nickname andra --query objectId -o tsv)

# I added my user in the group from the portal

# Get the resource ID of your AKS 
AKS_ID=$(az aks show \
    --resource-group AndraResourceGroup \
    --name ADManagedCluster \
    --query id -o tsv)

az role assignment create \
  --assignee $APPDEV_ID \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope $AKS_ID

az role assignment create \
  --assignee $APPDEV_ID \
  --role "Azure Kubernetes Service RBAC Writer" \
  --scope $AKS_ID

az role assignment create --role "Azure Kubernetes Service RBAC Admin" --assignee 993a6a4f-a850-4738-95be-8c05803eb92e --scope  $AKS_ID

az aks get-credentials --resource-group AndraResourceGroup --name ADManagedCluster --admin

cat <<EOF > role.yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dev-user-full-access
  namespace: default
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources:
  - jobs
  - cronjobs
  verbs: ["*"]
 
EOF
 
kubectl apply -f role.yaml
 
az ad group show --group demo --query objectId -o tsv
 
cat <<EOF > bind.yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dev-user-access
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: dev-user-full-access
subjects:
- kind: Group
  namespace: default
  name: 0951c492-1985-4842-bd95-2cc6c826ab3b 
EOF

kubectl apply -f bind.yaml



az aks get-credentials --resource-group AndraResourceGroup --name ADManagedCluster --overwrite-existing 