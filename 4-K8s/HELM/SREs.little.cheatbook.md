---
Title: HELM little cheat book
---



###### 1. How do I check <u>all</u> helm releases from a namespace by query Tiller (helm client version < v3):

```shell
  helm ls --namespace dev-env --tls
```


###### 2. Dump of custom values used in a previous deployment, useful when most custom values are "recycled" in the new deployment:

```shell
helm get values -a dev-env-mdb001-mongodb --tls > dev-env-mdb001-mongodb.yaml
```



###### 3. Delete (uninstall) a helm release; using flag `--purge` to delete any resource associated with deployment:

```shell
helm delete dev-env-mdb001-mongodb --purge --tls
```



###### 4. How do I check if persistent volumes have been released (PV claim has been deleted) and if they are deleted by the k8s scheduler? (reclaim policy on volume must be set "Delete" to work that; otherwise manually delete PVC and then PV, <u>mandatory</u> in that order)

```shell
kubectl get pv | grep dev-env
kubectl get pvc -n dev-env
```



###### 5. Middleware installation with explicit version of chart and custom file of values.yaml

```shell
helm upgrade --install -f iaw-mdb001-mongodb.yaml --namespace dev-env --debug --tls --version 7.3.1 dev-env-mdb001-mongodb stable/mongodb
```



###### 6. How do I check that all the middleware needed for a solution deployment is up & running:

```shell
kubectl get pods -n dev-env | grep -E 'mongo|mysql'
```
```
dev-env-mdb001-mongodb                              1/1     Running     0          18m
dev-env-mysql001                                    1/1     Running     0          4m8s
```



###### 7. How do I check the output of a helm deployment:

```shell
helm status dev-env-mdb001-mongodb --tls
```



###### 8. Installing a solution using a custom file of values.yaml with the newest version of the helm chart:

```shell
helm upgrade --install -f dev-env-mongo-dev.yaml --namespace dev-env --debug --tls dev-env-mongo-dev bmrg-charts/dev-env-mongo
```



###### 9. How do I list and filter multiple helm releases simultaneously

```shell
helm ls --namespace dev-env --tls | grep -E 'mongo|mysql|agent'
```


###### 10. How to list and filter multiple pods simultaneously in a namespace

```shell
kubectl get pods -n dev-env | grep -E 'mongo|mysql|agent'                                 
```
_If I want to follow the above output with refresh every 5 seconds:_

```shell
watch -n 5 'kubectl get pods -n dev-env | grep -E '\''mongo|mysql|agent'\'''
```
