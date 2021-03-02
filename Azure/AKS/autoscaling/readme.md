Cluster autoscaler  measures the usage of each node against the node pool's total demand for capacity, and works based on Pod resource requests ( that is: how many resources your Pods have requested).
Cluster autoscaler does not take into account the resources your Pods are actively using.
Essentially, cluster autoscaler trusts that the Pod resource requests you've provided are accurate and schedules Pods on nodes based on that assumption.
 

Lab:
Creating a User nodepool with 0 instances
Deploy a simple nginx to that node => this will automatically create an instance on that node [so from 0 will become 1]
Scale the deployment to increase the number of nodes in the nodepool
Scale down the deployment
Set the nodepool back to 0 instances

Create a User type nodepool with 0 instances  with label disktype=ssd  

``` 
az aks nodepool add --cluster-name scale-cluster --resource-group sclae-gr \
                      --name manual  --mode User --labels disktype=ssd  \
                      --node-count 0 \
                      --enable-cluster-autoscaler \
                      --min-count 0 \
                      --max-count 5 \
                      --node-vm-size  Standard_NC6 \
                      --os-type Linux \
                      --kubernetes-version 1.19.6
```
 
Values used are for example purpose.
You are nor required to use same values
--cluster-name Your-Cluster-Name
--resource-group Your-group-Name

# Test the autoscaler
  
## there should be only 0 node running

```
az aks nodepool list --cluster-name scale-cluster  --resource-group sclae-gr -o table  
                                                                
Name       OsType    VmSize      Count    MaxPods    ProvisioningState    Mode                                                                                                                                               
 ---------  --------  ------------  -------  ---------  -------------------  -----                                                                                                                                     
manual     Linux     Standard_NC6   0        110        Succeeded            User                        
nodepool1  Linux     Standard_NC6   2        110        Succeeded            System   
```

```
# deploy a single nginx container
cat <<EOF > test-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-manual
  labels:
    app: autoscaler-test-manual
spec:
  replicas: 1
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
      nodeSelector:
        disktype: ssd
EOF
```

`kubectl apply -f test-app.yaml`

```
# scale it to 40 instances
kubectl scale --replicas=40 -f test-app.yaml
 
# wait a moment and check if nodes were started and all 40 pods are in running state
# 20 ngnix pods fit into a single Standard_NC6 machine     
# so 40 should fit into 2 Standard_NC6 machines
```

```
# Get pending pods
kubectl get pods | grep Pending
 
# when scaling down Kubernetes will first scale down the Pending ones
kubectl get pods | grep Pending | wc -l
 
# Scale down to 4 replicas
kubectl scale --replicas=4 -f test-app.yaml
```

# Scale down the node instances from 2 to 0
> You cannot set a lower minimum than the current node count in this node pool. 
If you want to set a lower minimum node count, you will need to manually scale down the cluster first.


# Scale the nodepool instances to a number smaller than current node-count

```
#Scale the nodepool to 0 instances
az aks nodepool scale --cluster-name scale-cluster  --resource-group sclae-gr --name manual --node-count 0 
 
#List the nodepool to see if the scaling applied 
az aks nodepool list --cluster-name scale-cluster  --resource-group sclae-gr -o table  
```

# Delete the deployment
 
``` 
# delete test app
kubectl delete -f test-app.yaml
# by default autoscaler will scale down nodes after 10 minutes of inactivity
kubectl get nodes
```