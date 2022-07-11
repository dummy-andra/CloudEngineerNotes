
# If Autoscale do not work

>The cluster autoscaler is based on metrics and it will not scale  the node pool because has no metrics to trigger.

<br />

>Let’s try the following procedure:
- Disable the cluster autoscaler
- Increase the node instances from 0 to at least 1
- Enable the autoscaler

<br />

# In CLI insert the commands bellow as fallow:

# 1. Disable the cluster auto-scaler
```
az aks nodepool update \
  --resource-group neuro-compute \
  --cluster-name neuro-compute \
  --name np85ea814614 \
  --disable-cluster-autoscaler \
  --debug
```

# 2. Increase the node instances to 1 (or more) via --node-count <put here number> 
```
 az aks nodepool scale --cluster-name  neuro-compute --name np85ea814614 --resource-group neuro-compute  --node-count 1  -- debug
```

# 3. Enable the autoscaler
```
 az aks nodepool update \
  --resource-group neuro-compute \
  --cluster-name neuro-compute \
  --name np85ea814614 \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --debug
```

Resources:
              https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler


<br />


# When a similar problem is encountered what needs to be checked:

- that there are no pods running on the last node (check every namespace, the pods that have to run on every node do no count: fluentd, kube-dns, kube-proxy), the fact that there are no cronjobs is not enough
- that for the autoscaler is NOT enabled for the corresponding managed instance groups since they are different tools
- that there are no pods stuck in any weird state still assigned to that node
- that there is no pods waiting to be scheduled in the cluster