

services "sample-api" is forbidden: User "system:serviceaccount:default:***" cannot get resource "services" in API group "" in the namespace "xyz"


I have use the following command to configure role for default:default and the error still exists:
kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default

I saw the use in error message is "system:serviceaccount:default:***" rather than "default:default", I cannot find any information what the user of "default:***" is.


Fixed the issue by defining role with corresponding permissions and rolebinding 

```
cat <<EOF > bind.yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: aksandra-user-write-access
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources:
  - jobs
  - cronjobs
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete","write"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: aksandra-user-access
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: aksandra-user-write-access
subjects:
- kind: User
  namespace: default
  name: andranecula@microsoft.com
EOF
```


