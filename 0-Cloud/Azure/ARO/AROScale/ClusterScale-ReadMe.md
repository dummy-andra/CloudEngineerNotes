
Documentation:

Cluster Scaling:

Manual scaling  (Manually scaling a machine set | Machine management | OpenShift Container Platform 4.6)[https://docs.openshift.com/container-platform/4.6/machine_management/manually-scaling-machineset.html]
Cluster autoscaling (Applying autoscaling to a cluster | Machine management | OpenShift Container Platform 4.6)[https://docs.openshift.com/container-platform/4.6/machine_management/applying-autoscaling.html]



Here is an example of ClusterAutoscaler yaml:

$ cat machine-autoscale-example.yaml
apiVersion: "autoscaling.openshift.io/v1"
kind: "ClusterAutoscaler"
metadata:
  name: "default"
spec:
  resourceLimits:
    maxNodesTotal: 10
  scaleDown:
    enabled: true
    delayAfterAdd: 10s
    delayAfterDelete: 10s
    delayAfterFailure: 10s

oc create -f cluster-autoscaler.yaml
clusterautoscaler.autoscaling.openshift.io/default created
 

Note	The ClusterAutoscaler is not a namespaced resource — it exists at the cluster scope.


Autoscaler it's activated when there are pending pods and it will create a new instance to schedule the pending pods on it.


A good piece of information that I like to share is this workshop Azure Red Hat OpenShift Workshop (aroworkshop.io) 

Please let me know if you need more information,
