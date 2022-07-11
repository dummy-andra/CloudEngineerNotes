
#Set up Storage Account
AZURE_FILES_RESOURCE_GROUP=aro_azure_files
AZURE_STORAGE_ACCOUNT_NAME=aroazurefilessa
LOCATION=westeurope

az group create -l $LOCATION -n $AZURE_FILES_RESOURCE_GROUP

az storage account create \
	--name $AZURE_STORAGE_ACCOUNT_NAME \
	--resource-group $AZURE_FILES_RESOURCE_GROUP \
	--kind StorageV2 \
	--sku Premium_LRS

#Set resource group permissions
CLUSTER=aro-spn-cluster-demo 
ARO_RESOURCE_GROUP=aro-spn-group-domo 

ARO_SERVICE_PRINCIPAL_ID=$(az aro show -g $ARO_RESOURCE_GROUP -n $CLUSTER --query servicePrincipalProfile.clientId -o tsv)
az role assignment create --role Contributor --assignee $ARO_SERVICE_PRINCIPAL_ID -g $AZURE_FILES_RESOURCE_GROUP

#Set ARO cluster permissions
CLUSTER=aro-spn-cluster-demo 
ARO_RESOURCE_GROUP=aro-spn-group-domo 
ARO_API_SERVER=$(az aro list --query "[?contains(name,'$CLUSTER')].[apiserverProfile.url]" -o tsv)
oc login -u kubeadmin -p $(az aro list-credentials -g $ARO_RESOURCE_GROUP -n $CLUSTER --query=kubeadminPassword -o tsv) $ARO_API_SERVER

oc create clusterrole azure-secret-reader \
	--verb=create,delete,get,list,update,watch,patch \
	--resource=secrets

oc adm policy add-cluster-role-to-user azure-secret-reader system:serviceaccount:kube-system:persistent-volume-binder


subscriptionId=f3241abf-19ce-4e2e-be44-09db7c120a07

az feature register \
    --name AllowNfsFileShares \
    --namespace Microsoft.Storage \
    --subscription $subscriptionId

az feature show --name AllowNfsFileShares --namespace Microsoft.Storage --query properties.state

az feature show \
    --name AllowNfsFileShares \
    --namespace Microsoft.Storage \
    --subscription $subscriptionId

az provider register \
    --namespace Microsoft.Storage



# To prevent error: User "system:serviceaccount:kube-system:persistent-volume-binder"
#   cannot create resource "secrets" in API group "" in the namespace "default"
# See https://bugzilla.redhat.com/show_bug.cgi?id=1575933
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:controller:persistent-volume-binder
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: system:controller:persistent-volume-binder
subjects:
- kind: ServiceAccount
  name: persistent-volume-binder
EOF
oc policy add-role-to-user admin system:serviceaccount:kube-system:persistent-volume-binder -n default


LOCATION=westeurope
AZURE_STORAGE_ACCOUNT_NAME=arospnazurefile
AZURE_FILES_RESOURCE_GROUP=aro_azure_files

cat << EOF >> azure-storageclass-azure-file.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: azure-file
provisioner: kubernetes.io/azure-file
parameters:
  location: $LOCATION
  secretNamespace: default
  skuName: Premium_LRS
  storageAccount: $AZURE_STORAGE_ACCOUNT_NAME
  resourceGroup: $AZURE_FILES_RESOURCE_GROUP
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF


oc create -f azure-storageclass-azure-file.yaml


cat <<EOF | kubectl apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: $sc_name
provisioner: kubernetes.io/azure-file
mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=0
  - gid=0
  - mfsymlinks
  - cache=strict
  - actimeo=30
  - noperm
parameters:
  skuName: Standard_LRS
  location: $location
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-azurefile
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: azure-file
EOF


# Create PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $pvc_name
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: $sc_name
  resources:
    requests:
      storage: 1Gi
EOF








# Deployment & Service
perf_tier=gold
name=api-$perf_tier
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  labels:
    app: $name
    deploymethod: trident
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
        app: $name
        deploymethod: trident
    spec:
      containers:
      - name: $name
        image: erjosito/sqlapi:1.0
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: disk01
          mountPath: /mnt/disk
      volumes:
      - name: disk01
        persistentVolumeClaim:
          claimName: pvc-azurefile
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: $name
  name: $name
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: $name
  type: LoadBalancer
EOF



# Deployment & Service
perf_tier=gold
name=api-$perf_tier
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  labels:
    app: $name
    deploymethod: trident
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
        app: $name
        deploymethod: trident
    spec:
      containers:
      - name: $name
        image: nginx
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: disk01
          mountPath: /mnt/disk
      volumes:
      - name: disk01
        persistentVolumeClaim:
          claimName: pvc-azurefile
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: $name
  name: $name
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: $name
  type: LoadBalancer
EOF


cat <<EOF | oc apply -f -
kind: Pod
 
apiVersion: v1
 
metadata:
 
  name: nginx
 
spec:
 
  containers:
 
    - name: nginxfrontend
 
      image: nginx
 
      volumeMounts:
 
      - mountPath: "/mnt/Azure"
 
        name: volume
 
  volumes:
 
    - name: volume
 
      persistentVolumeClaim:
 
        claimName: pvc-azurefile
EOF



# Create storage account with NFS https://docs.microsoft.com/en-us/azure/storage/files/storage-files-how-to-create-nfs-shares?tabs=azure-portal
https://github.com/ezYakaEagle442/aro-pub-storage/blob/master/setup-store-CSI-driver-azure-file.md
https://github.com/kubernetes-sigs/azurefile-csi-driver/tree/master/deploy/example/nfs

#Set resource group permissions
CLUSTER=aro-spn-cluster-demo 
ARO_RESOURCE_GROUP=aro-spn-group-domo 

LOCATION=westeurope
AZURE_STORAGE_ACCOUNT_NAME=arospnnfs
AZURE_FILES_RESOURCE_GROUP=aro_azure_files

ARO_SERVICE_PRINCIPAL_ID=$(az aro show -g $ARO_RESOURCE_GROUP -n $CLUSTER --query servicePrincipalProfile.clientId -o tsv)
az role assignment create --role Contributor --assignee $ARO_SERVICE_PRINCIPAL_ID -g $AZURE_FILES_RESOURCE_GROUP

#Set ARO cluster permissions
ARO_API_SERVER=$(az aro list --query "[?contains(name,'$CLUSTER')].[apiserverProfile.url]" -o tsv)
oc login -u kubeadmin -p $(az aro list-credentials -g $ARO_RESOURCE_GROUP -n $CLUSTER --query=kubeadminPassword -o tsv) $ARO_API_SERVER

oc create clusterrole azure-secret-nfs-reader \
	--verb=create,delete,get,list,update,watch,patch \
	--resource=secrets

oc adm policy add-cluster-role-to-user azure-secret-nfs-reader system:serviceaccount:kube-system:persistent-volume-binder



cat <<EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile-csi-nfs
provisioner: file.csi.azure.com
parameters:
  protocol: nfs
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF








cat <<EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
 name: azurefile-csi-nfs
provisioner: file.csi.azure.com
parameters:
    protocol: nfs
    resourceGroup: $AZURE_FILES_RESOURCE_GROUP
    storageAccount: $AZURE_STORAGE_ACCOUNT_NAME
    location: $LOCATION
    secretNamespace: default
    skuName: Premium_LRS
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF


cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: azurefile-csi-nfs
EOF


cat <<EOF | oc apply -f -
kind: Pod
 
apiVersion: v1
 
metadata:
 
  name: nfs
 
spec:
 
  containers:
 
    - name: nginxfrontend
 
      image: nginx
 
      volumeMounts:
 
      - mountPath: "/mnt/Azure"
 
        name: volume
 
  volumes:
 
    - name: volume
 
      persistentVolumeClaim:
 
        claimName: pvc-nfs
EOF


For NFS

1.	I created an ARO Cluster with SP
2.	I installed the azure CSI drivers fallowing this repo
3.	I created the Storage Account also tested manually the NFS Create an NFS share - Azure Files | Microsoft Docs
4.	You can also check this azurefile-csi-driver/deploy/example/nfs at master · kubernetes-sigs/azurefile-csi-driver (github.com) and this Ali Boyraz – Medium  for inspiration


#Set resource group permissions
CLUSTER=aro-spn-cluster-demo 
ARO_RESOURCE_GROUP=aro-spn-group-domo 

LOCATION=westeurope
AZURE_STORAGE_ACCOUNT_NAME=arospnnfs
AZURE_FILES_RESOURCE_GROUP=aro_azure_files

ARO_SERVICE_PRINCIPAL_ID=$(az aro show -g $ARO_RESOURCE_GROUP -n $CLUSTER --query servicePrincipalProfile.clientId -o tsv)
az role assignment create --role Contributor --assignee $ARO_SERVICE_PRINCIPAL_ID -g $AZURE_FILES_RESOURCE_GROUP

#Set ARO cluster permissions
ARO_API_SERVER=$(az aro list --query "[?contains(name,'$CLUSTER')].[apiserverProfile.url]" -o tsv)
oc login -u kubeadmin -p $(az aro list-credentials -g $ARO_RESOURCE_GROUP -n $CLUSTER --query=kubeadminPassword -o tsv) $ARO_API_SERVER

oc create clusterrole azure-secret-nfs-reader \
    --verb=create,delete,get,list,update,watch,patch \
    --resource=secrets

oc adm policy add-cluster-role-to-user azure-secret-nfs-reader system:serviceaccount:kube-system:persistent-volume-binder


cat <<EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
 name: azurefile-csi-nfs
provisioner: file.csi.azure.com
parameters:
    protocol: nfs
    resourceGroup: $AZURE_FILES_RESOURCE_GROUP
    storageAccount: $AZURE_STORAGE_ACCOUNT_NAME
    location: $LOCATION
    secretNamespace: default
    skuName: Premium_LRS
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: azurefile-csi-nfs
EOF


cat <<EOF | oc apply -f -
kind: Pod
 
apiVersion: v1
 
metadata:
 
  name: nfs
 
spec:
 
  containers:
 
    - name: nginxfrontend
 
      image: nginx
 
      volumeMounts:
 
      - mountPath: "/mnt/Azure"
 
        name: volume
 
  volumes:
 
    - name: volume
 
      persistentVolumeClaim:
 
        claimName: pvc-nfs
EOF


CLUSTER=aro-spn-cluster-demo 
ARO_RESOURCE_GROUP=aro-spn-group-domo 

ARO_API_SERVER=$(az aro list --query "[?contains(name,'$CLUSTER')].[apiserverProfile.url]" -o tsv)
oc login -u kubeadmin -p $(az aro list-credentials -g $ARO_RESOURCE_GROUP -n $CLUSTER --query=kubeadminPassword -o tsv) $ARO_API_SERVER

cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: local-test-reader
spec:
  selector:
    matchLabels:
      koki.io/selector.name: local-test-reader
  strategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        koki.io/selector.name: local-test-reader
    spec:
      containers:
      - image: nginx
        name: reader
        volumeMounts:
        - mountPath: /usr/test-pod
          mountPropagation: HostToContainer
          name: local-vol
      volumes:
      - name: local-vol
        persistentVolumeClaim:
          claimName: pvc-propa2

---


apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-propa2
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: managed-premium  
EOF


# Deployment & Service
perf_tier=gold
name=api-$perf_tier
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: local-test-reader3
spec:
  selector:
    matchLabels:
      koki.io/selector.name: local-test-reader3
  strategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        koki.io/selector.name: local-test-reader3
    spec:
      containers:
      - image: nginx
        name: reader2
        volumeMounts:
        - mountPath: /usr/test-pod
          mountPropagation: HostToContainer
          name: local-vol
      volumes:
      - name: local-vol
        persistentVolumeClaim:
          claimName: example-local-claim2
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-local-pv2
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 5Gi
  local:
    path: /mnt/disks/ssd1
  persistentVolumeReclaimPolicy: Delete
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
              - dev-volume
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-local-claim2
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  selector:
    matchLabels:
      koki.io/selector.name: example-local-claim
  storageClassName: managed-premium
EOF