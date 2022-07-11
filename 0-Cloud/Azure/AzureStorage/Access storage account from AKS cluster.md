> # Access storage account from AKS cluster






<br />

**Steps**

- create myResourceGroup
- create network vnet 
- create AKS cluster with Network type (plugin)Azure CNI using as a network myVirtualNetwork
- create azure storage in myResourceGroup




<br />

> Get access via “private endpoint”

![](\pics\Outlook-mxeopuwc.png)





![Outlook-vjaealmu](\pics\Outlook-vjaealmu.png)





![Outlook-yxes5xye](\pics\Outlook-yxes5xye.png)





![Outlook-yfd2covq](\pics\Outlook-yfd2covq.png)




<br />

> ### I gave my workstation IP ( my local IP) access to upload an image on the blob container. I will cut it off after this

<br />


![Outlook-b5z3hiiw](\pics\Outlook-b5z3hiiw.png)



![image (5)](\pics\image5.png)





![image (1)](\pics\image1.png)




<br />

From the aks pod:

![image (2)](\pics\image2.png)


<br />


From the local station:

![Outlook-gnjja1vt](\pics\Outlook-gnjja1vt.png)




<br />

> ### If you do not use Private Endpoint connection, let's do it using Firewalls and virtual networks with Selected networks instead 

<br />

<br />

**I will remove my endpoint** 

![image (3)](\pics\image3.png)



![image (4)](\pics\image4.png)





![image (5)](\pics\image5.png)


<br />

**Try again from the aks pod**

![image (6)](\pics\image6.png)






<br />

> # Access Azure Storage from a Private AKS Cluster

<br />


```shell
az group create --name test-storage --location eastus



az network vnet create \

 --name test-storage-vnet \

 --resource-group test-storage \

 --subnet-name default

 

az network vnet subnet create \

 --address-prefixes 10.0.4.0/22\

 --name aks-subnet \

 --resource-group test-storage \

 --vnet-name test-storage-vnet





az network vnet subnet list --resource-group test-storage --vnet-name test-storage -vnet





az aks create \

  --resource-group test-storage \

  --name private-aks \

  --load-balancer-sku standard \

  --enable-private-cluster \

  --network-plugin azure \

  --vnet-subnet-id /subscriptions/<your-subs>/resourceGroups/test-storage /providers/Microsoft.Network/virtualNetworks/test-storage-vnet/subnets/aks-subnet \

  --docker-bridge-address 172.17.0.1/16 \

  --dns-service-ip 10.2.0.10 \

  --service-cidr 10.2.0.0/24
```

<br />


**Create the Azure Storage account**

<br />


![](\pics\download.png)



<br />


**Add**:

virtual network  `test-storage-vnet`

subnet  `aks-subnet`




<br />

**For testing:**

<br />


> A private cluster can be accessed only from a VM inside the VNET

<br />


I decided to create a special subnet for the VM to keep VM and aks subnets, separated

```bash
az network vnet subnet create \

 --address-prefixes 10.0.2.0/24\

 --name devops-subnet \

 --resource-group test-storage-vnet \

 --vnet-name test-storage-vnet



az vm create \

 --resource-group test-storage \

 --name devopsagent \

 --image UbuntuLTS \

 --admin-username azureuser \

 --generate-ssh-keys \

 --subnet devops-subnet \

 --vnet-name test-storage-vnet
```

<br />


Connect and prepare the vm
<br />


```bash
ssh azureuser@publicIpAddress
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo az aks install-cli
```


<br />

Connect to AKS cluster and create a pod
<br />

```bash
az aks get-credentials --resource-group test-storage --name private-aks
```



```bash
cat <<EOF > curl-ds.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl-ds
  labels:
    app: autoscaler-test-manual
spec:
  replicas: 0
  selector:
    matchLabels:
      app: autoscaler-test-manual
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: autoscaler-test-manual
        tier: frontend
    spec:
      containers:
      - image: nginx
        name: nginx
        command: ["/bin/sh","-c"]
        args: ["while true; do curl -v -k -I https://privatest.blob.core.windows.net/pictures/andra.jpeg ; done"]

EOF

kubectl apply -f curl-ds.yaml
kubectl scale --replicas=1 -f curl-ds.yaml
```



```bash
# Connect to pod and test the download with 
wget https://privatest.blob.core.windows.net/pictures/andra.jpeg 
```

![](\pics\download1.png)