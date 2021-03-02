
> You can't integrate Azure RBAC for Kubernetes authorization into existing clusters during preview, but you will be able to at General Availability (GA).
For now, only when creating a cluster
 
 
 

# Defin Permissions using Roles or ClusterRoles

> You define permissions within a Role or ClusterRole object. A Role defines access to resources within a single Namespace, while a ClusterRole defines access to resources in the entire cluster (cluster-scoped resources such as nodes)

```
cat <<EOF > role.yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user-see-access
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


cat <<EOF > bind.yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: aksandra
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: user-see-access
subjects:
- kind: User
  namespace: default
  name: put your desired user here
EOF

cat <<EOF > cluster2.yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: pod-reader2
rules:
- apiGroups: [""] 
  resources: ["*"]
  verbs: ["get", "watch", "list"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pod-reader-binding2
subjects:
- kind: Group
  name: system:serviceaccounts
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-reader2
  apiGroup: rbac.authorization.k8s.io
EOF


cat <<EOF > cluster.yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] 
  resources: ["*"]
  verbs: ["get", "watch", "list"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pod-reader-binding
subjects:
- kind: User
  namespace: default
  name: put your desired user here
roleRef:
  kind: ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

```